Class SourceControl.Git.Build
{

ClassMethod BuildUIForDevMode(devMode As %Boolean, rootDirectory As %String)
{
    if 'devMode {
        return
    }
    write !, "In developer mode, building web UI:"
    set webUIDirectory = ##class(%File).SubDirectoryName(rootDirectory, "git-webui")
    write !, "npm install"
    write !, $zf(-100, "/SHELL", "cd", webUIDirectory, "&&", "npm", "install")
    write !, "npm run build"
    write !, $zf(-100, "/SHELL", "cd", webUIDirectory, "&&", "npm", "run", "build")
}

}

