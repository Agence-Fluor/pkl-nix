# pkl-nix

`pkl-nix` est une bibliothèque Pkl versionnée : `Flake.pkl` décrit le flake et
`Nix.pkl` représente les valeurs Nix. Le renderer de `Flake.pkl` produit du
texte Nix déterministe, avec des clés triées. Il n'évalue rien et ne possède
ni store, ni daemon, ni lockfile.

Dans un projet Pkl, déclarez le paquet publié :

```pkl
amends "pkl:Project"
dependencies {
  ["nix"] {
    uri = "package://pkg.pkl-lang.org/github.com/Agence-Fluor/pkl-nix/pkl-nix@0.1.0"
  }
}
```

Puis créez `flake.pkl` :

```pkl
#!/usr/bin/env -S pkl eval
amends "@nix/Flake.pkl"
import "@nix/Nix.pkl" as Nix

description = "Exemple"
inputs {
  ["nixpkgs"] = new Nix.Input {
    url = "github:NixOS/nixpkgs/nixos-unstable"
  }
}
packages {
  ["x86_64-linux"] {
    ["hello"] = new Nix.Ref {
      path = "inputs.nixpkgs.legacyPackages.x86_64-linux.hello"
    }
  }
}
```

Exécutez `pkl project resolve` une fois pour créer le fichier standard
`PklProject.deps.json`. Après `chmod +x flake.pkl`, `./flake.pkl` produit le Nix
sur la sortie standard. [L'exemple complet](https://github.com/Agence-Fluor/pkl-nix-tools/tree/master/example)
montre le rendu, le build et l'exécution avec le wrapper `pkl-nix-tools`.

Le schéma expose `description`, `inputs`, `nixConfig`, `packages`,
`devShells`, `apps`, `checks`, `formatter`, `overlays`, `nixosModules`,
`nixosConfigurations`, `legacyPackages`, `templates`, `bundlers`,
`hydraJobs` et `custom`. Les quatre premières sorties utilisent des clés
`système → nom → expression` ; `formatter` utilise `système → expression`.
Les noms historiques (`defaultPackage`, `defaultApp`, `devShell`,
`defaultBundler`, `overlay`, `nixosModule`, `defaultTemplate`) restent
disponibles, même si Nix les déconseille.

`Nix.Input` couvre l'URL, `follows`, `flake`, les overrides d'inputs et les
principaux attributs des fetchers (`type`, `owner`, `repo`, `ref`, `rev`,
`narHash`, `dir`, `path`, etc.). `extra` accepte les attributs propres à un
fetcher. `Nix.App` et `Nix.Template` décrivent les sorties correspondantes.
`Nix.Attrs`, `Nix.ListExpr` et `Nix.Path` représentent les structures et
chemins Nix. `custom` accepte toute autre sortie, par exemple `lib`.

`Nix.Ref { path = "inputs.nixpkgs..." }` insère une référence Nix.
`Nix.Raw { code = "..." }` insère exactement le code fourni, y compris les
fonctions, dérivations et constructions Nix que le schéma ne modélise pas.
`outputsExpr` accepte une fonction `outputs` Nix entière lorsque les champs
structurés ne conviennent pas. Les chaînes Pkl ordinaires sont échappées
comme chaînes Nix, y compris `${`.

Pour voir le rendu directement :

```sh
pkl eval example/flake.pkl
sh scripts/test-package.sh
sh scripts/package-pkl.sh
pkl-nix-tools develop
```

`PklProject` contient la version du package. La
pipeline GitHub vérifie le schéma et le package, puis publie les quatre
artefacts Pkl sur les tags `pkl-nix@<version>`, comme les autres packages du
dépôt. `pkl-nix-tools` suit les modules et le lock Pkl dans son fingerprint.
Le shebang utilise Pkl directement ; le wrapper est nécessaire aux commandes Nix.
Pour publier, commitez la version puis utilisez le tag calculé depuis `PklProject` :

```sh
tag=$(sh scripts/release-tag.sh)
git tag "$tag"
git push github "$tag"
```
