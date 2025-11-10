<#
PowerShell script: push_and_push_docker.ps1
Purpose: Push assignment to GitHub and build+push Docker image to Docker Hub.
#>

# ----------------- USER CONFIG -----------------
$GitHubUser = "2024ht66532"
$RepoName   = "aceest-fitness-flask-devops-assignment-2"
$ProjectDir = "C:\Projects\aceest-fitness-flask-devops-assignment-2"

# ----------------- START -----------------
if (-not (Test-Path $ProjectDir)) {
    Write-Error "Project directory not found: $ProjectDir`nPlease unzip the provided ZIP to that location and re-run."
    exit 1
}

Set-Location $ProjectDir
Write-Host "Working directory: $ProjectDir"

# Prompt for GitHub token (secure)
$ghToken = Read-Host "Enter your GitHub Personal Access Token (will not be shown)" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ghToken)
$plainGHToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Prompt for Docker Hub credentials (secure)
$dockerUser = Read-Host "Enter your Docker Hub username (or press Enter to skip Docker push)"
if ($dockerUser -ne "") {
    $dockerPassSecure = Read-Host "Enter your Docker Hub password or token (hidden)" -AsSecureString
    $BSTR2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($dockerPassSecure)
    $plainDockerPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2)
} else {
    $plainDockerPass = ""
}

# ---- Git configuration ----
git config --global user.name "Uday Kumar Katipaga"
git config --global user.email "ukatipag@synaptics.com"
git config core.autocrlf true

# ---- Initialize repo if needed ----
if (-not (Test-Path ".git")) {
    git init
    Write-Host "Initialized new git repository."
}

git branch -M main

# ---- Setup remote ----
$repoUrl = "https://github.com/$GitHubUser/$RepoName.git"
git remote remove origin 2>$null
git remote add origin $repoUrl
Write-Host "Set remote origin to $repoUrl"

# ---- Add, commit files ----
git add .
$hasChanges = git status --porcelain
if ($hasChanges) {
    git commit -m "Assignment 2: ACEest Fitness CI/CD project"
} else {
    Write-Host "No local changes to commit."
}

# ---- Push to GitHub using token ----
Write-Host "Pushing to GitHub (force to ensure repo mirrors local)..."
$pushUrl = "https://$GitHubUser:$plainGHToken@github.com/$GitHubUser/$RepoName.git"
git push $pushUrl main --force
if ($LASTEXITCODE -ne 0) {
    Write-Error "Git push failed. Check token, network, and repo settings."
    exit 2
}
Write-Host "Git push successful: https://github.com/$GitHubUser/$RepoName"

# ---- Docker steps (optional) ----
if ($dockerUser -ne "") {
    try {
        $shortHash = git rev-parse --short HEAD 2>$null
        if (-not $shortHash) { throw "" }
        $tag = $shortHash.Trim()
    } catch {
        $tag = (Get-Date -Format "yyyyMMddHHmmss")
    }
    $imageName = "$dockerUser/aceest-fitness:$tag"

    Write-Host "Building Docker image: $imageName"
    docker build -t $imageName .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed. Make sure Docker daemon is running."
        exit 3
    }

    Write-Host "Logging in to Docker Hub as $dockerUser"
    echo $plainDockerPass | docker login -u $dockerUser --password-stdin
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker login failed. Check username/password and network."
        exit 4
    }

    Write-Host "Pushing image to Docker Hub: $imageName"
    docker push $imageName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker push failed."
        exit 5
    }
    $latestTag = "$dockerUser/aceest-fitness:latest"
    docker tag $imageName $latestTag
    docker push $latestTag
    Write-Host "Docker image pushed: $imageName and $latestTag"
}

Write-Host "`nAll done!"
Write-Host " - GitHub repo: https://github.com/$GitHubUser/$RepoName"
if ($dockerUser -ne "") { Write-Host " - Docker image: $imageName (and latest)" }
