Class SourceControl.Git.Build
{

ClassMethod BuildUIForDevMode(devMode As %Boolean, rootDirectory As %String)
{
    if 'devMode {
        return
    }
    write !, "In developer mode, building web UI:"
    set webUIDirectory = ##class(%File).SubDirectoryName(rootDirectory, "git-webui")
    write !, "npm ci"
    write !, $zf(-100, "/SHELL", "npm", "ci", "--prefix", webUIDirectory)
    write !, "npm run build"
    write !, $zf(-100, "/SHELL", "npm", "run", "build", "--prefix", webUIDirectory)
}

}
