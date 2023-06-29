{ pkgs, lib, config, ... }: 

{
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    aliases = {
      st = "status";
      di = "diff";
      co = "checkout";
      cm = "commit";
      cs = "commit -S";
      csf = "commit -S --amend --no-edit";
      br = "branch";
      sta = "stash";
      llog = "log --date=local";
      flog = "log --pretty=fuller --decorate";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an> [%G?]%Creset' --abbrev-commit --date=relative";
      lol = "log --graph --decorate --oneline";
      lola = "log --graph --decorate --oneline --all";
      blog = "log origin/master... --left-right";
      ds = "diff --staged";
      fixup = "commit --fixup";
      squash = "commit --squash";
      unstage = "reset HEAD";
      run = "rebase master@{u}";
      pom = "push origin master";
      poh = "push origin HEAD";
    };
    userName = lib.mkDefault "Winston R. Milling";
    userEmail = lib.mkDefault "Winston@Milli.ng";
    signing.key = lib.mkDefault "0xA44A3B1758373973";
    signing.signByDefault = lib.mkDefault true;
    extraConfig = {
      credential.credentialStore = "gpg";
      credential.helper = "${pkgs.unstable.git-credential-manager}/bin/git-credential-manager";
      sendemail.smtpserver = "smtp.gmail.com";
      sendemail.smtpuser = "winston@wrmilling.com";
      sendemail.smtpencryption = "tls";
      sendemail.smtpserverport = 587;
    };
    ignores = [ ".direnv" "result" ];
  };
}
