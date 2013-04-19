\name{jsonRPCviaMQ.executeJsonRPC}
\alias{jsonRPCviaMQ.executeJsonRPC}
\title{jsonRPCviaMQ executeJsonRPC}
\description{
Execute a single RPC or batch of RPCs.

This method will decode the string and call 'executeRPC' for each valid RPC call found.

Input is the raw jsonRPC formatted request.
Output is the raw jsonRPC formatted response.
}
\usage{jsonRPCviaMQ.executeJsonRPC(rpcRequestString)}
\arguments{
  \item{rpcRequestString}{unparsed string in json-rpc format}
}



\author{Jesse Ross <jross@cornell.edu>}





