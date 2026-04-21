# cp secrets.nix.template secrets.nix

{
  users = {
    root.hashedPassword = "$7$GU..../....L/LgPLqlAeDKrFoCRg.rI0$/uh6sKlII6MYhXuGPMASNNpJmTiWnJS23f3XdgJnPF3"; # mkpasswd -m scrypt -R 11
    william.hashedPassword = "$7$GU..../....SfMKevZxbAMcB1FhV4Wli/$0izFD4ZBk6.KQ3F93aQ2iF7Y.8ao9AzQnmAwCt55SW2"; # mkpasswd -m scrypt -R 11
  };
}
