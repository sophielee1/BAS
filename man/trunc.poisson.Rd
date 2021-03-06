\name{tr.poisson}
\alias{tr.Poisson}
\alias{tr.poisson}
\title{Truncated Poisson Prior Distribution for Models}
\description{Creates an object representing the prior distribution on
  models for BAS using a truncated Poisson Distribution on the
  Model Size 
}
\usage{tr.poisson(lambda, trunc)
}
\arguments{\item{lambda}{parameter in the Poisson distribution
    representing expected model size with infinite predictors}
  \item{trunc}{parameter that determines truncation in the distribution
    i.e. P(M; lambda, trunc) = 0 if  M > trunc}
}
\value{returns an object of class "prior", with the family and
  hyerparameters.
}
\details{The Poisson prior distribution on model size is obtained by
  assigning each variable inclusion indicator independent Bernoulli
  distributions with probability w, and then taking a limit as p goes to
  infinity and w goes to zero, such that p*w converges to lambda.  The Truncated
  version assigns zero probability to all models of size M > trunc.
}
\seealso{\code{\link{bas.lm}}, \code{\link{Bernoulli}},\code{\link{uniform}}
}
\examples{tr.poisson(10, 50)} 

\author{Merlise Clyde}

