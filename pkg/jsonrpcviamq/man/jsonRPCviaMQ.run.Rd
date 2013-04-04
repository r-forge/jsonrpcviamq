\name{jsonRPCviaMQ.run}
\alias{jsonRPCviaMQ.run}
\title{
Run the json-rpc server.
}
\description{
Check the specified message queue for messages, sleeping between checks.  Will run for the
specified amount of time.
}
\usage{
status <- jsonRPCviaMQ.run(queue, host, duration, waitFor)
}
\arguments{
  \item{queue}{
Name of the queue to connect to.  Example: r-work-messages
}
  \item{host}{
Host running the queue server.  ActiveMQ example: tcp://machine.name:61616.
}
  \item{text}{
The text message to put onto the queue
The producer object created from \code{\link{jsonRPCviaMQ.factory.getProducerFor}}
}
}
\details{
.
}
\value{
Returns a positive number (i.e. > 0) if it was successful.
Returns a negative number (i.e. < 0) if it was unsuccessful.
}
\references{
.
}
\author{
Jesse Ross
}
\note{
.
}

\examples{
# TBD
}

\keyword{ json }
\keyword{ json-rpc }
\keyword{ rpc }
\keyword{ queue }
\keyword{ mq }