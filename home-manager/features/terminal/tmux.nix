{ pkgs, lib, config, ... }: 

{
  home.packages = with pkgs; [
    tmux
    tmuxPlugins.better-mouse-mode
  ];
  home.file.".tmux.conf".text = ''
    # Mouse options 
    set -g mouse on

    ## Start counting windows from 1
    set -g base-index 1
    setw -g mode-keys vi

    # Change default binding
    unbind C-b
    set-option -g prefix C-a
    bind-key C-a send-prefix

    ## titles
    set-window-option -g automatic-rename on
    set-option -g set-titles on

    ## Toggle copymode
    bind Escape copy-mode

    ##open and close splits
    bind -n C-v split-window -h
    bind -n C-h split-window -v
    bind -n C-x killp
    bind -n C-z resize-pane -Z
    unbind '"'
    unbind %

    # Use Ctrl-arrows to navigate text
    set-window-option -g xterm-keys on

    # Use Alt-arrow keys without prefix key to switch panes
    bind -n C-Left select-pane -L
    bind -n C-Right select-pane -R
    bind -n C-Up select-pane -U
    bind -n C-Down select-pane -D

    # Shift arrow to switch windows
    bind -n C-T new-window
    bind -n S-PageDown prev
    bind -n S-PageUp next
    bind-key -n C-j detach

    # No delay for escape key press
    set -sg escape-time 0

    # Reload tmux config
    bind r source-file ~/.tmux.conf

    set -g pane-active-border-style fg=cyan 
    setw -g aggressive-resize on

    # ----------------------
    # Status Bar
    # -----------------------
    set-option -g status on                # turn the status bar on
    set -g status-interval 15               # set update frequencey (default 15 seconds)
    set -g status-justify centre           # center window list for clarity
    set-option -g status-position bottom    # position the status bar at top of screen

    # visual notification of activity in other windows
    setw -g monitor-activity on
    set -g visual-activity on

    # set color for status bar
    set-option -g status-bg colour00 #base02
    set-option -g status-fg cyan

    set -g  window-status-style dim
    set -g  window-status-current-style bright
    set -g  window-status-separator ' | '

    # Don't show anything on the left side of the bar
    set -g status-left ""

    # Don't show anything on the right side of the bar
    set -g status-right ""
    set -g default-terminal screen-256color
    set -as terminal-overrides ',st*:kind@:kri@'

    set -g @prevent-scroll-for-fullscreen-alternate-buffer 'on'
    set -g @scroll-speed-num-lines-per-scroll '3'
    run-shell $HOME/.config/tmux/plugins/tmux-better-mouse-mode/scroll_copy_mode.tmux

    #
    # Powerline Cyan Block - Tmux Theme
    # Created by Jim Myhrberg <contact@jimeh.me>.
    #
    # Inspired by vim-powerline: https://github.com/Lokaltog/powerline
    #
    # Requires terminal to be using a powerline compatible font, find one here:
    # https://github.com/Lokaltog/powerline-fonts
    #

    # Status update interval
    set -g status-interval 1

    # Basic status bar colors
    set -g status-style fg=colour240,bg=colour233

    # Left side of status bar
    set -g status-left-style bg=colour233,fg=colour243
    set -g status-left-length 40
    set -g status-left "#[fg=colour232,bg=colour39,bold] #S #[fg=colour39,bg=colour240,nobold]#[fg=colour233,bg=colour240] #(whoami) #[fg=colour240,bg=colour235]#[fg=colour240,bg=colour235] #I:#P #[fg=colour235,bg=colour233,nobold]"

    # Right side of status bar
    set -g status-right-style bg=colour233,fg=colour243
    set -g status-right-length 150
    set -g status-right "#[fg=colour235,bg=colour233]#[fg=colour240,bg=colour235] %H:%M:%S #[fg=colour240,bg=colour235]#[fg=colour233,bg=colour240] %d-%b-%y #[fg=colour245,bg=colour240]#[fg=colour232,bg=colour245,bold] #H "

    # Window status
    set -g window-status-format " #I:#W#F "
    set -g window-status-current-format " #I:#W#F "

    # Current window status
    set -g window-status-current-style bg=colour39,fg=colour232

    # Window with activity status
    set -g window-status-activity-style bg=colour233,fg=colour75

    # Window separator
    set -g window-status-separator ""

    # Window status alignment
    set -g status-justify centre

    # Pane border
    set -g pane-border-style bg=default,fg=colour238

    # Active pane border
    set -g pane-active-border-style bg=default,fg=colour39

    # Pane number indicator
    set -g display-panes-colour colour233
    set -g display-panes-active-colour colour245

    # Clock mode
    set -g clock-mode-colour colour39
    set -g clock-mode-style 24

    # Message
    set -g message-style bg=colour39,fg=black

    # Command message
    set -g message-command-style bg=colour233,fg=black

    # Mode
    set -g mode-style bg=colour39,fg=colour232
  '';
}
