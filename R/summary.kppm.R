#'
#'       summary.kppm.R
#'
#'   $Revision: 1.4 $  $Date: 2015/04/25 21:43:11 $
#' 

summary.kppm <- function(object, ...) {
  nama <- names(object)
  result <- unclass(object)[!(nama %in% c("X", "po", "call", "callframe"))]
  ## handle old format
  if(is.null(result$isPCP)) result$isPCP <- TRUE
  ## summarise trend component
  result$trend <- summary(as.ppm(object), ...)
  theta <- coef(object)
  if(length(theta) > 0) {
    vc <- vcov(object, matrix.action="warn")
    if(!is.null(vc)) {
      se <- if(is.matrix(vc)) sqrt(diag(vc)) else
      if(length(vc) == 1) sqrt(vc) else NULL
    }
    if(!is.null(se)) {
      two <- qnorm(0.975)
      lo <- theta - two * se
      hi <- theta + two * se
      zval <- theta/se
      pval <- 2 * pnorm(abs(zval), lower.tail=FALSE)
      psig <- cut(pval, c(0,0.001, 0.01, 0.05, 1),
                  labels=c("***", "**", "*", "  "),
                  include.lowest=TRUE)
      ## table of coefficient estimates with SE and 95% CI
      result$coefs.SE.CI <- data.frame(Estimate=theta, S.E.=se,
                                       CI95.lo=lo, CI95.hi=hi,
                                       Ztest=psig,
                                       Zval=zval)
    }
  }
  class(result) <- "summary.kppm"
  return(result)
}

coef.summary.kppm <- function(object, ...) {
  return(object$coefs.SE.CI)
}

print.summary.kppm <- function(x, ...) {
  terselevel <- spatstat.options('terse')
  digits <- getOption('digits')
  isPCP <- x$isPCP
  splat(if(x$stationary) "Stationary" else "Inhomogeneous",
        if(isPCP) "cluster" else "Cox",
        "point process model")

  if(waxlyrical('extras', terselevel) && nchar(x$Xname) < 20)
    splat("Fitted to point pattern dataset", sQuote(x$Xname))

  if(waxlyrical('gory', terselevel)) {
    switch(x$Fit$method,
           mincon = {
             splat("Fitted by minimum contrast")
             splat("\tSummary statistic:", x$Fit$StatName)
           },
           clik  =,
           clik2 = {
             splat("Fitted by maximum second order composite likelihood")
             splat("\trmax =", x$Fit$rmax)
             if(!is.null(wtf <- x$Fit$weightfun)) {
               cat("\tweight function: ")
               print(wtf)
             }
           },
           palm = {
             splat("Fitted by maximum Palm likelihood")
             splat("\trmax =", x$Fit$rmax)
             if(!is.null(wtf <- x$Fit$weightfun)) {
               cat("\tweight function: ")
               print(wtf)
             }
           },
           warning(paste("Unrecognised fitting method", sQuote(x$Fit$method)))
           )
  }

  # ............... trend .........................

  parbreak()
  splat("----------- TREND MODEL -----")
  print(x$trend, ...)

  # ..................... clusters ................

  tableentry <- spatstatClusterModelInfo(x$clusters)
  
  parbreak()
  splat("-----------", 
        if(isPCP) "CLUSTER" else "COX",
        "MODEL",
        "-----------")
  splat("Model:", tableentry$printmodelname(x))
  parbreak()
  
  cm <- x$covmodel
  if(!isPCP) {
    # Covariance model - LGCP only
    splat("\tCovariance model:", cm$model)
    margs <- cm$margs
    if(!is.null(margs)) {
      nama <- names(margs)
      tags <- ifelse(nzchar(nama), paste(nama, "="), "")
      tagvalue <- paste(tags, margs)
      splat("\tCovariance parameters:",
            paste(tagvalue, collapse=", "))
    }
  }
  pa <- x$clustpar
  if (!is.null(pa)) {
    splat("Fitted",
          if(isPCP) "cluster" else "covariance",
          "parameters:")
    print(pa, digits=digits)
  }

  if(!is.null(mu <- x$mu)) {
    if(isPCP) {
      splat("Mean cluster size: ",
            if(!is.im(mu)) paste(signif(mu, digits), "points") else "[pixel image]")
    } else {
      splat("Fitted mean of log of random intensity:",
            if(!is.im(mu)) signif(mu, digits) else "[pixel image]")
    }
  }
  invisible(NULL)
}