{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    
    signing.key = lib.mkDefault "0xA44A3B1758373973";
    signing.signByDefault = lib.mkDefault true;
    settings = {
      credential.credentialStore = "gpg";
      credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      sendemail.smtpserver = "smtp.gmail.com";
      sendemail.smtpuser = "winston@wrmilling.com";
      sendemail.smtpencryption = "tls";
      sendemail.smtpserverport = 587;
      user = {
        name = lib.mkDefault "Winston R. Milling";
        email = lib.mkDefault "Winston@Milli.ng";
      };
      alias = {
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
    };
    ignores = [
      ".direnv"
      "result"
    ];
  };
}
