\name{eplogprob.marg}
\alias{eplogprob.marg}
\title{eplogprob.marg - Compute approximate marginal inclusion probabilities
  from pvalues}
\description{\code{eplogprob.marg} calculates approximate marginal posterior
  inclusion probabilities from p-values computed from a series of simple
  linear regression models using a lower bound approximation to Bayes
  factors.  Used to order variables and if appropriate  obtain initial
  inclusion probabilities  for sampling using Bayesian Adaptive Sampling
  \code{bas.lm} 
}
\usage{eplogprob.marg(Y, X, thresh=.5, max = 0.99, int=TRUE)}
\arguments{
  \item{Y}{response variable}
  \item{X}{design matrix with a column of ones for the intercept}
  \item{thresh}{the value of the inclusion probability when if the  p-value >
    1/exp(1), where the lower bound approximation is not valid.}
  \item{max}{maximum value of the inclusion probability; used for
   the \code{bas.lm} function to keep initial inclusion probabilities
   away from 1.}
 \item{int}{If the Intercept is included in the linear model, set
   the marginal inclusion probability corresponding to the intercept to 1}
}    
\value{ \code{eplogprob.prob} returns a vector of marginal posterior inclusion
  probabilities  for each of the variables in the linear model. If int =
  TRUE, then the inclusion probability for the intercept is set to 1.  
}

\details{Sellke, Bayarri and Berger (2001) provide a simple calibration
  of p-values 

  BF(p) = -e p log(p)

which provide a lower bound to a Bayes factor for
comparing H0: beta = 0 versus H1: beta not equal to 0,  when the p-value
p  is less than 1/e.  Using equal prior odds on the hypotheses H0 and
H1, the approximate marginal posterior inclusion probability

  p(beta != 0 | data ) = 1/(1 + BF(p))

When p > 1/e, we set the marginal inclusion probability to 0.5 or the
value given by \code{thresh}.
For the eplogprob.marg the marginal p-values are obtained using
statistics from the p simple linear regressions

P(F > (n-2) R2/(1 - R2))  where F ~ F(1, n-2)
where R2 is the square of the correlation coefficient between y and X_j.
}
\references{Sellke, Thomas, Bayarri, M. J., and  Berger, James O.  (2001), ``Calibration of p-values for testing precise null hypotheses'', The American Statistician, 55, 62-71.
}
\seealso{\code{\link{bas}}
}
\examples{
library(MASS)
data(UScrime)
UScrime[,-2] = log(UScrime[,-2])
eplogprob(lm(y ~ ., data=UScrime))
}
\author{Merlise Clyde \email{clyde@stat.duke.edu}}
\keyword{regression}

