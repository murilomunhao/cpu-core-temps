# Página do produto — CPU Core Temps

Site: **https://murilomunhao.github.io/cpu-core-temps**

## Publicar no GitHub Pages

No repositório [murilomunhao/cpu-core-temps](https://github.com/murilomunhao/cpu-core-temps):

### Opção A — pasta `/docs` (recomendada)

```bash
mkdir -p docs
cp index.html docs/
git add docs/index.html
git commit -m "Add GitHub Pages site"
git push
```

Em **Settings → Pages → Source**: branch principal, pasta `/docs`.

### Opção B — branch `gh-pages`

```bash
git checkout --orphan gh-pages
git rm -rf .
cp index.html .
git add index.html
git commit -m "GitHub Pages"
git push -u origin gh-pages
```

Em **Settings → Pages**, selecione a branch `gh-pages`.

A URL final será: https://murilomunhao.github.io/cpu-core-temps
