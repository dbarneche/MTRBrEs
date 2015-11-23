######################
# AUXILLIARY FUNCTIONS
######################
make.transparent <- function(col, opacity=0.5) {
  if (length(opacity) > 1 && any(is.na(opacity))) {
    n <- max(length(col), length(opacity))
    opacity <- rep(opacity, length.out=n)
    col <- rep(col, length.out=n)
    ok <- !is.na(opacity)
    ret <- rep(NA, length(col))
    ret[ok] <- Recall(col[ok], opacity[ok])
    ret
  } else {
    tmp <- col2rgb(col)/255
    rgb(tmp[1,], tmp[2,], tmp[3,], alpha=opacity)
  }
}

label <- function(px, py, lab, adj=c(0, 1), text=TRUE, log=FALSE, ...) {
  usr  <-  par('usr')
  x.p  <-  usr[1] + px*(usr[2] - usr[1])
  y.p  <-  usr[3] + py*(usr[4] - usr[3])
  if(log=='x'){x.p<-10^(x.p)}
  if(log=='y'){y.p<-10^(y.p)}
  if(log=='xy'){x.p<-10^(x.p);y.p<-10^(y.p)}
  if(text){
    text(x.p, y.p, lab, adj=adj, ...)
  } else {
    points(x.p, y.p, ...)
  }
}

to.pdf <- function(expr, filename, ...) {
  to.dev(expr, pdf, filename, ...)
}

fig.path  <-  function(name) {
  file.path('output/figures', name)
}

to.dev <- function(expr, dev, filename, ..., verbose=TRUE) {
  if ( verbose )
    cat(sprintf('Creating %s\n', filename))
  dev(filename, family='CM Roman', ...)
  on.exit(dev.off())
  eval.parent(substitute(expr))
}

to.pdf <- function(expr, filename, ...) {
  to.dev(expr, pdf, filename, ...)
}

linearRescale <- function(x, r.out) {
  p <- (x - min(x)) / (max(x) - min(x))
  r.out[[1]] + p * (r.out[[2]] - r.out[[1]])
}

rounded  <-  function(value, precision=1, change=FALSE) {
  if(change) {
    value  <-  value * -1
  }
  sprintf(paste0('%.', precision, 'f'), round(value, precision))
}

###########################
# SPECIES AS RANFOM EFFECTS
###########################
plotResp  <-  function() {
  # color for the 4 species
  cols  <-  c('Bryo'='dodgerblue2', 'Sponge'='tomato', 'Bugula'='darkolivegreen3', 'Stolonifera'='darkgoldenrod')
  metRates$cols  <-  cols[match(metRates$Species, names(cols))]

  # extract fixed effects first
  xnBoTs <-  fixef(modelLmer)['(Intercept)']
  xnEr   <-  fixef(modelLmer)['invKT']
  xnA    <-  fixef(modelLmer)['lnMass']

  # extract random effects - deviations from fixed effects
  nres   <-  ranef(modelLmer)$Species
  nBoTs  <-  xnBoTs + nres[['(Intercept)']][match(metRates$Species, rownames(nres))]
  nA     <-  rep(xnA, length(nBoTs))
  nEg    <-  xnEr + nres$invKT[match(metRates$Species, rownames(nres))]
  
  #corrects metabolic rates for temperature first and then size scaling
  btNlmer  <-  metRates$lnRate - nEg*metRates$invKT
  bwNlmer  <-  metRates$lnRate - nA*metRates$lnMass
  
  par(mfrow=c(1, 2), mar=c(5.1,4.1,4.1,3), omi=c(0.5,1,0.5,2), cex=1, family='Times')
  #(a)
  plot(btNlmer ~ metRates$lnMass, pch=21, col=metRates$cols, bg=make.transparent(metRates$cols, .5),  xlab='ln(Mass) (g)', ylab=expression(paste('ln(Metabolic rate @ 20'*degree,'C) (g C d'^{-1}, ')'), sep=''), las=1, xlim=c(-1, 6), ylim=c(-3, 5), cex.lab=1.3, xpd=NA)  

  for(j in 1:nrow(nres)) {
    xpoints  <-  range(metRates$lnMass[metRates$Species == rownames(nres)[j]])
    xpoints  <-  seq(xpoints[1], xpoints[2], length.out=50)
    nresA    <-  xnA + nres[['lnMass']][j]
    expr     <-  (xnBoTs + nres[['(Intercept)']][j]) + nresA*xpoints
    points(xpoints, expr, type='l', lty=2, col='grey30', lwd=1.5)
  }
  points(c(-2, 7), xnBoTs + xnA*c(-2, 7), type='l', lty=1, col='black', lwd=2.5)
  #fig position label
  label(px=0, py=1.1, '(a)', cex=1.2, font=3, adj=c(0.5,0.5), xpd=NA)
  #trends labels
  label(px=c(.85,.95), py=c(.95,.95), text=FALSE, type='l', lty=1, lwd=2.5, col='black', adj=c(0.5,0.5))
  label(px=.84, py=.95, lab=substitute('mean trend: '~italic(y)== B + A*italic(x), list(B=substr(xnBoTs,1,5), A=round(xnA,2))), cex=0.9, adj=c(1, 0.5))
  label(px=c(.85,.95), py=c(.88,.88), text=FALSE, type='l', lty=2, lwd=1.5, col='grey30', adj=c(0.5,0.5))  
  label(px=.84, py=.88, lab='species-level variation', cex=0.9, adj=c(1, 0.5))

  #(b)
  plot(metRates$invKT, bwNlmer, pch=21, col=metRates$cols, bg=make.transparent(metRates$cols, .5),  xlab=expression(paste('Inverse Temperature, 1/', italic(kT[s]), ' - 1/', italic(kT), ' (eV'^-1,')', sep='')), ylab=expression(paste('ln(Metabolic rate @ 1 g) (g C d'^{-1}, ')'), sep=''), las=1, xlim=c(-3, 1), ylim=c(-5.5, 3), cex.lab=1.3, xpd=NA, xaxt='n')
  axis(1, at=round(1/8.62e-5*(1/288.15-1/(273.15+seq(-3,37,by=10))), 2))
  axis(side=3, at=round(1/8.62e-5*(1/288.15-1/(273.15+seq(-3,37,by=10))),2), labels=seq(-3,37,by=10))

  for(j in 1:nrow(nres)) {
    xpoints  <-  range(metRates$invKT[metRates$Species == rownames(nres)[j]])
    xpoints  <-  seq(xpoints[1], xpoints[2], length.out=50)
    nresEr   <-  xnEr + nres[['invKT']][j]
    expr     <-  (xnBoTs + nres[['(Intercept)']][j]) + nresEr*xpoints
    points(xpoints, expr, type='l', lty=2, col='grey30', lwd=1.5)
  }
  
  mean.nx           <-  1/8.62e-5*(1/288.15-1/(263:323))
  mean.expr.nlmer  <-  xnBoTs + xnEr*mean.nx
  points(mean.nx, mean.expr.nlmer, type='l', lty=1, col='black', lwd=2.5)
  #fig position label
  label(px=0, py=1.1, '(b)', cex=1.2, font=3, adj=c(0.5,0.5), xpd=NA)
  #trends labels
  label(px=c(.85,.95), py=c(.95,.95), text=FALSE, type='l', lty=1, lwd=2.5, col='black', adj=c(0.5,0.5))
  label(px=.84, py=.95, lab=substitute('mean trend: '~italic(y)== B + A*italic(x), list(B=substr(xnBoTs,1,5), A=round(xnEr,2))), cex=0.9, adj=c(1, 0.5))
  label(px=c(.85,.95), py=c(.88,.88), text=FALSE, type='l', lty=2, lwd=1.5, col='grey30', adj=c(0.5,0.5))  
  label(px=.84, py=.88, lab='species-level variation', cex=0.9, adj=c(1, 0.5))

  label(px=.5, py=1.25, expression(paste('Temperature ('*degree,'C)',sep='')), xpd=NA, cex=1.3, adj=c(0.5,0.5))

  for(k in seq_along(cols)) {
    label(1.1, 1-k*0.1, text=FALSE, pch=21, col=cols[k], bg=make.transparent(cols[k], .5), adj=c(0.5, 0.5), xpd=NA)
    label(1.15, 1-k*0.1, names(cols)[k], adj=c(0, 0.5), xpd=NA, font=3)
  }
}