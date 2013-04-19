\name{jsonRPCviaMQ.runForever}
\alias{jsonRPCviaMQ.runForever}
\title{jsonRPCviaMQ runForever}
\description{
Convenience method.

Connect to a queue, check for a single message and execute if a valid message was received.
Never exit, continue checking for messages indefinitely.
Sleep for 'waitForS' seconds between message checks.
}
\usage{jsonRPCviaMQ.runForever(queue, host, queueType, waitForS = 60)}
\arguments{
  \item{queue}{
}
  \item{host}{
}
  \item{queueType}{
}
  \item{waitForS}{
}
}



\author{Jesse Ross <jross@cornell.edu>}





