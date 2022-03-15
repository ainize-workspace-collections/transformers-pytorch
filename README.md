<h1 align="center">
    Transformers Pytorch
    <br>
</h1>

This branch is for creating Ainize Workspace images.

## Installed Python libraries

### How to Test Your Image

Build Docker Image

```bash
docker build -t <image-name> .
```

Run Docker

```bash
docker run -d -p 8000:8000 -p 8010:8010 -p 8020:8020 <image-name>
```

Run Docker with Password

```bash
docker run -d -p 8000:8000 -p 8010:8010 -p 8020:8020 -e PASSWORD=<password> <image-name>
```

Run Docker with Github Repo

```bash
docker run -d -p 8000:8000 -p 8010:8010 -p 8020:8020 -e GH_REPO=<github-repo> <image-name>
```

Run Docker with password and Github Repo

```bash
docker run -d -p 8000:8000 -p 8010:8010 -p 8020:8020 -e PASSWORD=<password> -e GH_REPO=<github-repo> <image-name>
```

- Jupyter Notebook : http://server-address:8000/
- Visual Studio Code : http://server-address:8010/
- Terminal - ttyd : http://server-address:8020/

### How to use this image in Ainize Workspace

1. Click the "Create your workspace" button on the [Ainize Workspace page](https://ainize.ai/workspace).
2. As the Container option, select "Import from github".
3. Click the "Start with repo url" button.
4. Put "https://github.com/ainize-workspace-collections/transformers-pytorch" in "Enter a Github repo url". And select the branch what you want to deploy.
5. Select the required tool(s) and click the OK button.
6. Click "Start my work" after selecting the machine type.
   Now, enjoy your own Ainize Workspace! 🎉
