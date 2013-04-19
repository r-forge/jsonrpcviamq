\name{jsonRPCviaMQ.run}
\alias{jsonRPCviaMQ.run}
\title{jsonRPCviaMQ run}
\description{
The real logic

Connect to a queue, check for a single message and execute if a valid message was received.
durationS indicates how many seconds to run this 'server' for.
waitForS indicates how long to 'sleep' between checks of the queue.
queueType indicates the type of queue to query, valid values are 'activeMQ' and 'rabbitMQ' as per https://code.google.com/p/r-message-queue/

returns the number of messages processed.
}
\usage{jsonRPCviaMQ.run(queue, host = "tcp://localhost:61616", queueType = "activeMQ", 
    durationS = -1, waitForS = 60)}
\arguments{
  \item{queue}{name of queue to pull messages from}
  \item{host}{server hosting the queue specified above, default is tcp://localhost:61616}
  \item{queueType}{type of queue, currently supports activeMQ and rabbitMQ}
  \item{durationS}{duration to run, in seconds, before exiting}
  \item{waitForS}{time to wait, in seconds, before checking the queue if no work was found during the previous check}
}



\author{Jesse Ross <jross@cornell.edu>}





