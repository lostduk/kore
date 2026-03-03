{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [ inputs.llm-agents.pi ];

    persistence."/persist".files = [ ".pi/agent/auth.json" ]; 
  };
}
