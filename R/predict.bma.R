predict.basglm = function(object, newdata, top=NULL, type=c("link", "response"), ...) {
#    browser()
    pred = predict.bas(object, newdata, top)
    if (length(type) > 1) type = type[1]
    if (type == "response") {
        Ypred = apply(pred$Ypred, 1, FUN = function(x) {eval(object$call$family)$linkinv(x)})
        if (top > 1) {
            Ybma = Ypred %*% pred$postprobs}
        else Ybma = Ypred

        pred = list(Ypred=Ypred, Ybma=Ybma, postprobs=pred$postprobs, best=pred$best)
    }   
    return(pred)       
}

    
    
predict.bas = function(object, newdata, top=NULL, type="link", 
                       estimator="BMA", se=FALSE, prediction=TRUE, ...) {
  if (!(estimator %in% c("BMA", "HPM", "MPM", "BPM"))) {
    stop("Estimator must be one of 'BMA', 'BPM', 'HPM', or 'MPM'.")
  }
  if (missing(newdata) || is.null(newdata))  {
    newdata= object$X
    prediction= FALSE}
  if (is.data.frame(newdata)) {
      newdata = model.matrix(eval(object$call$formula), newdata) 
  }
  if (is.vector(newdata)) newdata=matrix(newdata, nrow=1)  
  
  n <- nrow(newdata)
  if (ncol(newdata) == object$n.vars) newdata=newdata[,-1, drop=FALSE]  # drop intercept
  if (ncol(newdata) != (object$n.vars -1)) stop("Dimension of newdata does not match orginal model")
  if (!is.null(object$mean.x)) newdata = sweep(newdata, 2, object$mean.x)


  if (estimator == "MPM" ) {
      nvar = object$n.vars -1
      bestmodel<- (0:nvar)[object$probne0 > .5]
      newdata = cbind(1,newdata)
      best = 1
      models <- rep(0, nvar+1)
      models[bestmodel+1] <- 1
      if (sum(models) > 1) {
          object <- bas.lm(eval(object$call$formula),
                           data=eval(object$call$data), 
                           weights=eval(object$call$weights),
                           n.models=1, alpha=object$g,
                           initprobs=object$probne0, 
                           prior=object$prior, modelprior=object$modelprior,
                           update=NULL,bestmodel=models,
                           prob.local=.0)
          best= which.max(object$postprobs)
          fit  <- as.vector(newdata[,object$which[[best]]+1, drop=FALSE] %*% object$mle[[best]]) * object$shrinkage[[best]]
          fit = fit + (1 - object$shrinkage[[best]])*(object$mle[[best]])[1]
      }
      else { fit = rep(nrow(newdata), 1) * as.numeric(object$mle[object$size == 1])}
      models=bestmodel
      attributes(fit) = list(model = models)
      
      Ybma = fit
      Ypred = NULL
      postprobs=NULL
      best=NULL
  }
  else {    
  if (estimator == "HPM") top=1
  postprobs <- object$postprobs
  best <- order(-postprobs)
  if (!is.null(top)) best <- best[1:top]
  models <- object$which[best]
  beta <- object$mle[best]
  gg <- object$shrinkage[best]
  intercept <- object$intercept[best]  
  postprobs <- postprobs[best]
  postprobs <- postprobs/sum(postprobs)
  M <- length(postprobs)
  Ypred <- matrix(0, M, n)
                                        # lm case
  if (is.null(intercept)) {      
      for (i in 1:M) {
          beta.m <- beta[[i]]
          model.m <- models[[i]]
          Ypred[i,] <-  (newdata[,model.m[-1],drop=FALSE] %*% beta.m[-1])*gg[i]  + beta.m[1]}
  }
  else {
     for (i in 1:M) { 
      beta.m <- beta[[i]]
      model.m <- models[[i]]
      Ypred[i,] <-  (newdata[,model.m[-1],drop=FALSE] %*% beta.m[-1])*gg[i] + intercept[i]}
 }
  
  Ybma <- t(Ypred) %*% postprobs
  fit = Ybma
  if (estimator == "HPM") {
    models = unlist(object$which[best])
    attributes(fit) = list(model = models, best=best)  
  }
  if (estimator=="BPM") {
    dis =apply(sweep(Ypred, 2, Ybma),1, sd)
    bestBPM = which.min(dis)
    fit = Ypred[bestBPM, ]
    models = unlist(object$which[best[bestBPM]])
    best = bestBPM
    attributes(fit) = list(model = models,
                            best = best)
   
  }
  }
  se.calc = se
  
  se=list(se.fit=NULL, se.pred=NULL)
  
  if (se.calc)  {
    if (!prediction)  {
       if (estimator != "BMA")  se = .se.fit(fit,  object)   
       else   se = .se.bma(Ybma, Ypred, best, object) }
    else {
    warning("no standard errors available yet for out of sample prediction; returning NULL")}
    }
    
  return(list(fit=as.vector(fit), Ybma=Ybma, Ypred=Ypred, postprobs=postprobs,
              se.fit=se$se.fit, se.pred=se$se.pred,
              best=best, bestmodel=models))
}


fitted.bas = function(object,  type="response", estimator=NULL, top=NULL, ...) {
    if (type %in% c("HPM", "MPM", "BPM", "BMA")) {
        warning(paste("type = ", type,
                      " is being deprecated, use estimator = ", type))
        if (is.null(estimator)) estimator = type
    }
        
  nmodels = length(object$which)
  X = object$X
  if (estimator=="HPM") {
#    X = cbind(1,sweep(X[,-1], 2, object$mean.x))
#    best =  which.max(object$logmarg)
#    yhat  <- as.vector(X[,object$which[[best]]+1, drop=FALSE] %*% object$mle[[best]]) * object$shrinkage[[best]]
#   yhat = yhat + (1 - object$shrinkage[[best]])*(object$mle[[best]])[1]
   yhat = predict(object, X,  top=1, estimator="HPM")$fit
#  best = ypred$best
    #  yhat = ypred$fit   # note with ome model this is the HPM
      #attributes(yhat) = list(model = unlist(object$which[best]), best=best)   
  }
  if (estimator == "BMA") {
   yhat = predict(object, X, top, estimator="BMA")$fit
  }
  if (estimator == "MPM") {
    yhat = predict(object, X, top, estimator="MPM")$fit
#  nvar = ncol(X) - 1
#   X = cbind(1,sweep(X[,-1], 2, object$mean.x))
#   bestmodel<- (0:nvar)[object$probne0 > .5]
#   best = NA
#   model <- rep(0, nvar+1)
#   model[bestmodel+1] <- 1
#   if (sum(model) > 1) {
#      object <- bas.lm(eval(object$call$formula),
#                        data=eval(object$call$data), n.models=1, alpha=object$g,
#                        initprobs=object$probne0,
#                        prior=object$prior, update=NULL,bestmodel=model,
#                        prob.local=.0)
#     best=1
#    yhat  <- as.vector(X[,object$which[[best]]+1, drop=FALSE] %*% object$mle[[best]]) * object$shrinkage[[best]]
#     yhat = yhat + (1 - object$shrinkage[[best]])*(object$mle[[best]])[1]
# }
#   else { yhat = rep(nrow(X), 1) * as.numeric(object$mle[object$size == 1])}
#   attributes(yhat) = list(model = bestmodel)   
  }
  if (estimator=="BPM") {
      yhat = predict(object, X, top, estimator="BPM")$fit
#      ypred = predict(object, X, top=top)
#      dis =apply(sweep(ypred$Ypred, 2, ypred$Ybma),1, sd)
#     best = which.min(dis)
#      yhat = ypred$Ypred[best, ]
#      attributes(yhat) = list(model = unlist(object$which[ypred$best[best]]),
#                    best = ypred$best[best])
  }
return(yhat)
}

.se.fit= function(yhat, object) {
  n = object$n
  model = attr(yhat, "model")
  best = attr(yhat, "best")
  if (object$prior == "BIC" | object$prior == "AIC") {
    df = n - object$size[best]
} else {
  df = n - 1}

  shrinkage= object$shrinkage[best]
  xiXTXxiT = hat(object$X[, model[-1]+1]) -1/n
  scale_fit = 1/n + object$shrinkage[best]*xiXTXxiT
  ssy = var(object$Y)*(n-1)
  bayes_mse = ssy*(1 - shrinkage*object$R2[best])/df
  se.fit = sqrt(bayes_mse*scale_fit)
  se.pred = sqrt(bayes_mse*(1 + scale_fit))
  return(list(se.fit=se.fit, se.pred=se.pred, residual.scale=sqrt(bayes_mse)))
}

.se.bma = function(fit, Ypred, best, object){

n = object$n

if (object$prior == "BIC" | object$prior == "AIC") {
  df = n - object$size[best]
} else {
  df = n - 1}

shrinkage= object$shrinkage[best]
xiXTXxiT =  sapply(object$which[best], 
                   FUN=function(model, X) {
                     hat(X[, model[-1]+1]) -1/n}, 
                   object$X)

scale_fit = 1/n + sweep(xiXTXxiT, 2, shrinkage, FUN="*")
ssy = var(object$Y)*(n-1)
bayes_mse = ssy*(1 - shrinkage*object$R2[best])/df
var.fit = sweep(scale_fit, 2, bayes_mse, FUN="*")
var.pred = sweep((1 + scale_fit), 2, bayes_mse, FUN="*")

postprobs = object$postprobs[best]

# expected variance
evar.fit = as.vector(var.fit %*% postprobs)
evar.pred = as.vector(var.pred %*% postprobs)
# variance of expectations
var.efit = as.vector(postprobs %*% (sweep(Ypred, 2, fit))^2 )

se.fit = sqrt(evar.fit + var.efit)
se.pred = sqrt(evar.pred + var.efit)
  

return(list(se.fit=se.fit, se.pred=se.pred, residual.scale=sqrt(bayes_mse)))
}