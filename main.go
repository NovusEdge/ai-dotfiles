// claude-pick asks which Claude Code account to launch and prints its name on
// stdout. The TUI draws on stderr so the shell can capture stdout with $(...).
// "personal" is ~/.claude; every ~/.claude-<name> holding .credentials.json is
// another account. Exit status 1 means the user cancelled.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
)

type account struct {
	name, email string
}

func email(claudeJSON string) string {
	b, err := os.ReadFile(claudeJSON)
	if err != nil {
		return ""
	}
	var c struct {
		OAuthAccount struct {
			EmailAddress string `json:"emailAddress"`
		} `json:"oauthAccount"`
	}
	if json.Unmarshal(b, &c) != nil {
		return ""
	}
	return c.OAuthAccount.EmailAddress
}

func accounts(home string) []account {
	all := []account{{"personal", email(filepath.Join(home, ".claude.json"))}}
	dirs, _ := filepath.Glob(filepath.Join(home, ".claude-*"))
	for _, d := range dirs {
		if _, err := os.Stat(filepath.Join(d, ".credentials.json")); err != nil {
			continue
		}
		all = append(all, account{strings.TrimPrefix(filepath.Base(d), ".claude-"), email(filepath.Join(d, ".claude.json"))})
	}
	return all
}

var (
	title  = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#D97757")).MarginBottom(1)
	cursor = lipgloss.NewStyle().Foreground(lipgloss.Color("#D97757")).Bold(true)
	chosen = lipgloss.NewStyle().Bold(true)
	dim    = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	box    = lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).BorderForeground(lipgloss.Color("8")).Padding(0, 2)
)

// The row after the last account is "+ new account"; choosing it opens a name
// prompt and the result is that name, which the shell creates on launch.
type model struct {
	accts   []account
	pos     int
	picked  bool
	naming  bool
	newName string
}

func (m model) Init() tea.Cmd { return nil }

func (m model) taken(name string) bool {
	for _, a := range m.accts {
		if a.name == name {
			return true
		}
	}
	return false
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	k, ok := msg.(tea.KeyPressMsg)
	if !ok {
		return m, nil
	}
	if m.naming {
		switch k.String() {
		case "enter":
			if m.newName != "" && !m.taken(m.newName) {
				m.picked = true
				return m, tea.Quit
			}
		case "esc":
			m.naming, m.newName = false, ""
		case "ctrl+c":
			return m, tea.Quit
		case "backspace":
			if m.newName != "" {
				m.newName = m.newName[:len(m.newName)-1]
			}
		default:
			// The name becomes ~/.claude-<name> and a shell word.
			for _, r := range strings.ToLower(k.Text) {
				if r >= 'a' && r <= 'z' || r >= '0' && r <= '9' || r == '-' {
					m.newName += string(r)
				}
			}
		}
		return m, nil
	}
	rows := len(m.accts) + 1
	switch s := k.String(); s {
	case "up", "k", "shift+tab":
		m.pos = (m.pos + rows - 1) % rows
	case "down", "j", "tab":
		m.pos = (m.pos + 1) % rows
	case "n", "+":
		m.pos, m.naming = len(m.accts), true
	case "enter", "space":
		if m.pos == len(m.accts) {
			m.naming = true
			return m, nil
		}
		m.picked = true
		return m, tea.Quit
	case "esc", "q", "ctrl+c":
		return m, tea.Quit
	default:
		if len(s) == 1 && s[0] >= '1' && int(s[0]-'1') < len(m.accts) {
			m.pos, m.picked = int(s[0]-'1'), true
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m model) View() tea.View {
	if m.picked {
		return tea.NewView("")
	}
	var b strings.Builder
	b.WriteString(title.Render("Claude account") + "\n")
	for i, a := range m.accts {
		// Pad before styling: ANSI codes would count toward the width.
		mark, name := "  ", fmt.Sprintf("%-12s", a.name)
		if i == m.pos {
			mark, name = cursor.Render("› "), chosen.Render(name)
		}
		fmt.Fprintf(&b, "%s%s %s %s\n", mark, dim.Render(fmt.Sprint(i+1)), name, dim.Render(a.email))
	}
	help := "↑/↓ move · enter launch · 1-9 jump · n new · esc cancel"
	switch {
	case m.naming:
		note := "you'll log in once Claude starts"
		if m.taken(m.newName) {
			note = "that name is taken"
		}
		fmt.Fprintf(&b, "%s%s %s\n", cursor.Render("› "), dim.Render("+"), chosen.Render("name: "+m.newName+"█"))
		help = note + " · enter create · esc back"
	case m.pos == len(m.accts):
		fmt.Fprintf(&b, "%s%s %s\n", cursor.Render("› "), dim.Render("+"), chosen.Render("new account"))
	default:
		fmt.Fprintf(&b, "  %s %s\n", dim.Render("+"), dim.Render("new account"))
	}
	b.WriteString("\n" + dim.Render(help))
	return tea.NewView(box.Render(b.String()) + "\n")
}

func main() {
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	accts := accounts(home)
	last := filepath.Join(home, ".cache", "claude-profile")

	m := model{accts: accts}
	if b, err := os.ReadFile(last); err == nil {
		for i, a := range accts {
			if a.name == strings.TrimSpace(string(b)) {
				m.pos = i
			}
		}
	}

	res, err := tea.NewProgram(m, tea.WithOutput(os.Stderr)).Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	m = res.(model)
	if !m.picked {
		os.Exit(1)
	}

	name := m.newName
	if !m.naming {
		name = accts[m.pos].name
	}
	_ = os.WriteFile(last, []byte(name+"\n"), 0o644)
	fmt.Println(name)
}
