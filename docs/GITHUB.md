# Push this project to GitHub

## 1. Open the folder

Extract the project ZIP. In VS Code, choose **File → Open Folder → SnowOnMac**, then **Terminal → New Terminal**. The terminal should be inside the folder containing README.md.

## 2. Check it

```sh
./scripts/test.sh
./scripts/build.sh
```

## 3. Make the first local commit

```sh
git init -b main
git add .
git status
git commit -m "Initial SnowOnMac desktop snow prototype"
```

The `.gitignore` excludes build products and caches. Before committing, check the file list: it should contain source, scripts, tests and documentation, not the `build` folder. If Git requests your identity, configure your own name and email, then retry the commit.

## 4. Create an empty GitHub repository

On GitHub, create a repository called `snow-on-mac`. Choose public or private as you prefer. Leave the options to add a README, .gitignore and license unchecked because this project already includes the first two. You can choose a license later.

## 5. Connect and push

Replace `YOUR_USERNAME` below with your GitHub username:

```sh
git remote add origin https://github.com/YOUR_USERNAME/snow-on-mac.git
git push -u origin main
```

Authenticate using GitHub’s supported sign-in flow when prompted. If you already have an `origin` remote, inspect `git remote -v` before changing anything.

## 6. After publishing

Open the repository’s **Actions** tab to see the macOS checks. Add a screenshot or demo recording only after trying the app. Review the prototype limitations in README.md before describing it as finished.

No GitHub repository has been created or published by these project files.
