\name{jsonRPCviaMQ-package}
\alias{jsonRPCviaMQ-package}
\alias{jsonRPCviaMQ}
\docType{package}
\title{
Allow R to execute json-rpc 2.0 messages retrieved from a message queue (activeMQ, rabbitMQ)
}
\description{
This package provides a simple json-rpc server implementation, which retrieves messages
from a message queue (rabbitmq or activemq).

Why?
Allows us to setup worker R instances to leverage idle CPU time around the office.

Doesn't handle?
Batched RPC requests (yet).
}
\details{
\tabular{ll}{
Package: \tab jsonRPCviaMQ\cr
Type: \tab Package\cr
Version: \tab 1.0\cr
Date: \tab 2012-10-24\cr
License: \tab GPL\cr
}

.

}
\author{
Jesse Ross
Maintainer: Matt MacGillivray <matthew.macgillivray@cornell.edu>
}
\references{
json-rpc - http://www.jsonrpc.org/specification
futile.logger - https://github.com/muxspace/futile.logger
MessageQueue - http://r-message-queue.r-forge.r-project.org/
rJava - http://www.rforge.net/rJava/
Writing Java Extensions - http://cran.r-project.org/web/packages/helloJavaWorld/vignettes/helloJavaWorld.pdf
}
\keyword{ package }
\keyword{ json }
\keyword{ json-rpc }
\keyword{ rpc }
\keyword{ queue }
\keyword{ mq }
\seealso{
}
\examples{

# TODO - include a basic example
}
