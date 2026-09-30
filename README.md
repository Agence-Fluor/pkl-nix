# pkl-nix

`pkl-nix` est une bibliothèque Pkl versionnée : `Flake.pkl` décrit le flake et
`Nix.pkl` représente les valeurs Nix. Le renderer de `Flake.pkl` produit du
texte Nix déterministe, avec des clés triées. Nix assure ensuite l'évaluation,
les builds, le store et le verrouillage des inputs.

## Démarrer

Pour utiliser `./flake.pkl`, installez Bash 4+, Pkl 0.31.1+ et Nix avec
Flakes, puis déclarez les deux paquets publiés dans `PklProject` :

```pkl
amends "pkl:Project"
dependencies {
  ["nixTools"] { uri = "package://pkg.pkl-lang.org/github.com/Agence-Fluor/pkl-nix-tools/pkl-nix-tools@0.2.0" }
  ["nix"] {
    uri = "package://pkg.pkl-lang.org/github.com/Agence-Fluor/pkl-nix/pkl-nix@0.1.2"
  }
}
```

Puis créez `flake.pkl` :

```pkl
#!/usr/bin/env -S bash -ec 's=$(pkl eval -w "${0%/*}" -x launcher flake.pkl);eval "$s"'
amends "@nix/Flake.pkl"
import "@nix/Nix.pkl" as Nix
local launcher = import("@nixTools/Bootstrap.pkl").output.text

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

```sh
pkl project resolve
chmod +x flake.pkl
./flake.pkl build .#hello
pkl eval flake.pkl                    # afficher le Nix uniquement
```

Commitez `PklProject.deps.json` ; relancez `pkl project resolve` après avoir
modifié les dépendances. Le shebang charge le lanceur depuis le paquet
[`pkl-nix-tools`](https://github.com/Agence-Fluor/pkl-nix-tools#démarrer), sans
installation globale ni script extrait dans le projet. Pkl démarre à chaque
appel ; le rendu Nix reste en cache dans `.pkl-nix-tools/`.

La bibliothèque s'utilise aussi avec `pkl eval` : la dépendance `nix`,
`amends "@nix/Flake.pkl"` et les imports de types suffisent pour le rendu.
[L'exemple complet](https://github.com/Agence-Fluor/pkl-nix-tools/tree/master/example)
montre le build, l'exécution et le shell de développement.

## Schémas et expressions

Le schéma expose `description`, `inputs`, `nixConfig`, `packages`,
`devShells`, `apps`, `checks`, `formatter`, `overlays`, `nixosModules`,
`nixosConfigurations`, `legacyPackages`, `templates`, `bundlers`,
`hydraJobs` et `custom`. `packages`, `devShells`, `apps` et `checks` utilisent
des clés `système → nom → expression` ; `formatter` utilise `système → expression`.
Les noms historiques (`defaultPackage`, `defaultApp`, `devShell`,
`defaultBundler`, `overlay`, `nixosModule`, `defaultTemplate`) restent
disponibles, même si Nix les déconseille.

`Nix.Input` couvre l'URL, `follows`, `flake`, les overrides d'inputs et les
principaux attributs des fetchers (`type`, `owner`, `repo`, `ref`, `rev`,
`narHash`, `dir`, `path`, etc.). `extra` accepte les attributs propres à un
fetcher. `Nix.App` et `Nix.Template` décrivent les sorties correspondantes.
Comme dans Nix, utilisez soit une URL complète (avec `?dir=…` si nécessaire),
soit la forme structurée avec `type` et les attributs du fetcher. Ajouter
`dir` à côté d'une URL abrégée sans `type` n'est pas accepté par Nix.
`Nix.Attrs`, `Nix.ListExpr` et `Nix.Path` représentent les structures et
chemins Nix. `custom` accepte toute autre sortie, par exemple `lib`.

`Nix.MkShell` décrit `mkShell` avec un ensemble `pkgs`, une liste de noms de
paquets ou d'expressions, et éventuellement `shellHook`. `Nix.WithPackages`
décrit les environnements comme `python3.withPackages`. `Nix.Apply`,
`Nix.Lambda` et `Nix.InterpolatedString` couvrent l'application de fonctions,
les fonctions Nix et l'interpolation sans écrire de code Nix dans une chaîne.

`Nix.Ref { path = "inputs.nixpkgs..." }` insère une référence Nix.
`Nix.Raw { code = "..." }` insère exactement le code fourni, y compris les
fonctions, dérivations et constructions Nix que le schéma ne modélise pas.
`outputsExpr` accepte une fonction `outputs` Nix entière lorsque les champs
structurés ne conviennent pas. Les chaînes Pkl ordinaires sont échappées
comme chaînes Nix, y compris `${`.

## Développer et publier

```sh
pkl project resolve
./flake.pkl develop
pkl eval example/flake.pkl
sh scripts/test-package.sh
sh scripts/package-pkl.sh
```

`PklProject` contient la version du package. La
pipeline GitHub vérifie le schéma et le package, puis publie les quatre
artefacts Pkl sur les tags `pkl-nix@<version>`, comme les autres packages du
dépôt. `pkl-nix-tools` suit les modules et le lock Pkl dans son fingerprint.
Le shebang lance le wrapper ; la bibliothèque reste utilisable seule avec `pkl eval`.
Pour publier, commitez la version puis utilisez le tag calculé depuis `PklProject` :

```sh
tag=$(sh scripts/release-tag.sh)
git tag "$tag"
git push github "$tag"
```
