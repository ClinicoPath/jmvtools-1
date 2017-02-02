
#' @import jmvcore
NULL

jmcPath <- function() {
    system.file('node_modules', 'jamovi-compiler', 'index.js', package='jmvtools')
}

#' The current version
#'
#' returns the current version of jmvtools
#'
#' @export
version <- function() {
    lines <- readLines(system.file('DESCRIPTION', package='jmvtools'))
    version <- lines[grepl('^Version:', lines)]
    version <- substring(version, 10)
    version
}

#' Check that jmvtools is able to find jamovi
#'
#' @param home path to a local jamovi installation
#' @importFrom node node
#' @export
check <- function(home=NULL) {

    exe <- node()
    jmc <- jmcPath()

    args <- c(jmc, '--check')
    if (is.null(home))
        home <- getOption('jamovi_home')
    if ( ! is.null(home))
        args <- c(args, '--home', home)

    out <- system2(exe, args, stdout=TRUE, wait=TRUE)
    out <- paste0(out, collapse='\n')
    cat(out)
    cat('\n')
}

#' Build and install a local jamovi module into jamovi
#'
#' @param pkg path to a local directory containing the module source
#' @inheritParams check
#' @importFrom node node
#' @export
install <- function(pkg='.', home=NULL) {

    exe <- node()
    jmc <- jmcPath()

    args <- c(jmc, '--install', pkg)
    if (is.null(home))
        home <- getOption('jamovi_home')
    if ( ! is.null(home))
        args <- c(args, '--home', home)

    out <- system2(exe, args, stdout=TRUE, wait=TRUE)
    out <- paste0(out, collapse='\n')
    cat(out)
}

#' Prepare a jamovi source module
#'
#' @inheritParams install
#' @importFrom node node
#' @export
prepare <- function(pkg='.') {

    exe <- node()
    jmc <- jmcPath()

    args <- c(jmc, '--prepare', pkg)

    out <- system2(exe, args, stdout=TRUE, wait=TRUE)
    out <- paste0(out, collapse='\n')
    cat(out)
    cat('\n')
}

#' Create an empty jamovi module
#'
#' Creates an empty jamovi module. Astute observers will notice that empty
#' jamovi modules are the same as empty R packages.
#'
#' @param path location to create the new module (the name of the module is inferred from the path)
#' @export
create <- function(path='.') {

    path <- normalizePath(path, winslash='/', mustWork=FALSE)
    name <- basename(path)

    if (length(grep('^[a-zA-Z][a-zA-Z0-9]+$', name)) == 0)
        stop('Module names must be at least two characters long and consist only of letters and numbers')

    parentDir <- dirname(path)
    if ( ! file.exists(parentDir))
        stop(paste0('Parent directory \'', parentDir, '\' does not exist'))

    if (file.exists(path)) {
        if (length(dir(path)) > 0)
            stop('Directory already exists and is not empty', call.=FALSE)
    }
    else {
        dir.create(path)
    }

    dir.create(file.path(path, 'R'))
    dir.create(file.path(path, 'jamovi'))

    DESCRIPTION_path <- system.file('templates', 'DESCRIPTION', package='jmvtools', mustWork=TRUE)
    NAMESPACE_path   <- system.file('templates', 'NAMESPACE',   package='jmvtools', mustWork=TRUE)

    DESCRIPTION_content <- paste0(readLines(DESCRIPTION_path, encoding='UTF-8'), collapse='\n')
    NAMESPACE_content   <- paste0(readLines(NAMESPACE_path,   encoding='UTF-8'), collapse='\n')

    DESCRIPTION_content <- gsub('\\$NAME', name, DESCRIPTION_content)

    DESCRIPTION_path <- file.path(path, 'DESCRIPTION')
    NAMESPACE_path   <- file.path(path, 'NAMESPACE')

    writeLines(DESCRIPTION_content, DESCRIPTION_path)
    writeLines(NAMESPACE_content,   NAMESPACE_path)

    prepare(path)
}

#' Adds a new analysis to a jamovi module
#'
#' @param name the name for the new analysis
#' @param title the title for the new analysis
#' @inheritParams check
#' @export
addAnalysis <- function(name, title=name, path='.') {

    if ( ! is.character(name) && length(name) != 1)
        stop('title must be a string', call.=FALSE)

    if ( ! is.character(title) && length(name) != 1)
        stop('title must be a string', call.=FALSE)

    if (length(grep('^[a-zA-Z][a-zA-Z0-9]+$', name)) == 0)
        stop('Analysis names must be at least two characters long and consist only of letters and numbers')

    if ( ! file.exists(file.path(path, 'DESCRIPTION')))
        stop('path does not contain a DESCRITPION file, does not appear to be a package or module', call.=FALSE)

    jamoviPath <- file.path(path, 'jamovi')
    if ( ! dir.exists(jamoviPath))
        dir.create(jamoviPath)

    aYamlPath <- system.file('templates', 'a.yaml', package='jmvtools', mustWork=TRUE)
    rYamlPath <- system.file('templates', 'r.yaml', package='jmvtools', mustWork=TRUE)

    aYamlContent <- paste0(readLines(aYamlPath, encoding='UTF-8'), collapse='\n')
    rYamlContent <- paste0(readLines(rYamlPath, encoding='UTF-8'), collapse='\n')

    aYamlContent <- gsub('\\$NAME',  name,  aYamlContent)
    aYamlContent <- gsub('\\$TITLE', title, aYamlContent)
    rYamlContent <- gsub('\\$NAME',  name,  rYamlContent)
    rYamlContent <- gsub('\\$TITLE', title, rYamlContent)

    aYamlPath <- file.path(jamoviPath, paste0(tolower(name), '.a.yaml'))
    rYamlPath <- file.path(jamoviPath, paste0(tolower(name), '.r.yaml'))

    if (file.exists(aYamlPath))
        stop(paste0('analysis \'', name, '\' already exists'), call.=FALSE)

    writeLines(aYamlContent, aYamlPath)
    writeLines(rYamlContent, rYamlPath)

    prepare(path)
}