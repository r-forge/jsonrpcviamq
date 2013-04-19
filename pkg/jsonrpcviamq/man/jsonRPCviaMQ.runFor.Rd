\name{jsonRPCviaMQ.runFor}
\alias{jsonRPCviaMQ.runFor}
\title{jsonRPCviaMQ runFor}
\description{
Convenience method.

Connect to a queue, check for a single message and execute if a valid message was received.
Run for a specified duration, in seconds (i.e. 6hrs = 6*60*60).
Sleep for 'waitTimeS' seconds between message checks.
}
\usage{jsonRPCviaMQ.runFor(queue, host, queueType, durationS, waitForS = 60)}
\arguments{
  \item{queue}{
}
  \item{host}{
}
  \item{queueType}{
}
  \item{durationS}{
}
  \item{waitForS}{
}
}



\author{Jesse Ross <jross@cornell.edu>}





