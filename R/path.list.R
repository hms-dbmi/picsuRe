#' @author Gregoire Versmee, Laura Versmee
#' @export path.list

path.list <- function(env, var, token, verbose = FALSE) {

  # return the list  of all paths corresponding to the variables selected
  if (verbose)  message("\nRetrieving the selected pathways:")

  # Standardize the path name "/path/to/the/node
  var <- gsub("//", "/", paste0("/", trimws(var)))

  ## new school
  if (verbose)  message('  Using the "find" function of PICSURE')

  pathlist <- lapply(var, function(e) {
    path <- content.get(paste0(env, "/rest/v1/resourceService/find?term=", gsub("\\*", "%", basename(e))), token)
    path <- as.character(sapply(path, "[", "pui"))
    if (dirname(e) != ".")  path <- path[grepl(URLencode(dirname(e), reserved = TRUE), sapply(path, URLencode, reserved = TRUE))]
    if (all(is.na(path))) {
      message(paste0("\nNo variables associated with: ", e,
                     "\nPlease check the spelling, or see if there is any forbidden character such as forward slashes, trailing spaces. If so, ask the developpers to remove them."))
    } else {
      if (verbose)  message(paste0("\nRetrieving all variables associated with: ", e))
      plist <- flatten.tree(env, path, token, verbose)
      return(plist)
    }
  })

  if (length(pathlist)!=0)  return(pathlist)
  else {
    if (verbose) message('  No path found using the "find" function, trying the old-fasion way')

    ## go old school
    pathlist <- list()
    for (i in 1:length(var))  {

      end <- nchar(var[i])
      if (substr(var[i], end, end) == "/")  var[i] <- substr(var[i], 1, end-1)

      # Get the 1st arg of the variable path
      st <- unlist(strsplit(var[i], "/"))[2]

      # Get the 1rst node of the environment, until reaching the 1st arg of the variable path
      path1 <- paste0(env, "/rest/v1/resourceService/path")
      ind <- content.get(path1, token)

      # If node is i2b2, look at the next one
      pui <- ind[[1]][["pui"]]
      if (grepl("i2b2", pui))  pui <- ind[[2]][["pui"]]

      while (!any(grepl (st, pui, fixed = TRUE)))  {
        path2 <- paste0(path1, pui[1])
        listpui <- content.get(gsub("\\?", "%3F", path2), token)
        pui <- c()
        if (length(listpui) > 0)  {
          for (j in 1:length(listpui))  {
            pui <- c(pui, listpui[[j]][["pui"]])
          }
        } else {
          stop(paste0("Can't find the path ", '"', var[i], '", please check the spelling\nProcess stopped'), call. = FALSE)
        }
      }
      pui <- pui[which(grepl (st, pui, fixed = TRUE))]

      # Concat 1st node with the path to create the full path
      if (paste0("/", st) == var[i])  path <- pui
      else  path <- paste0(pui, sub(paste0("/", st, "/"), "", var[i], fixed = TRUE))

      if (verbose)  message(path)

      # Add to pathlist
      pathlist <- list(pathlist, path)
    }
    if (!is.null(pathlist))  message('!!!!! Please ask the developper to install the "find" function on your PICSURE environment in order to speed up the query process !!!!!')
    return(flatten.tree(env, path, token, verbose))
  }
}
