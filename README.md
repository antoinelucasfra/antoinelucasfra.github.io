# Antoine Lucas - Personal Website

A data science portfolio and blog built with [Quarto](https://quarto.org/).

Repository for the **Live site**: https://antoinelucasfra.github.io/

## Deployment

This site is automatically deployed to GitHub Pages using GitHub Actions. The workflow:

1. Triggers on push to the `main` branch or manual dispatch
2. Builds the Quarto site
3. Deploys to GitHub Pages

### GitHub Pages Setup

To enable automatic deployment, configure GitHub Pages in your repository settings:

1. Go to **Settings** → **Pages**
2. Under **Build and deployment**, set **Source** to **GitHub Actions**
3. The workflow will automatically deploy on the next push to `main`

You can also manually trigger a deployment from the **Actions** tab by running the "Publish Quarto Site" workflow.

## Local Development

To build the site locally:

```bash
quarto render
```

The rendered site will be in the `docs` directory.

## License

Content: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)
