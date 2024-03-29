##
# Set of methods monitor the specified message queue for JSON RPC calls.
#
# Includes jsonRPCviaMQ.echo method for testing.
#
# Error codes outlined here - http://www.jsonrpc.org/specification
# futile.logger outlined here - http://www.r-bloggers.com/better-logging-in-r-aka-futile-logger-1-3-0-released/
#
#
# Documentation uses 'inlinedocs' style, so Rd files are generated.
#
#
# author: Jesse Ross (jr634 at cornell)
# date: 3/21/13
#
# modifier: Matt MacGillivray (msm336 at cornell)
##



# BEGINNING DEV, building out the basic structure/documentation
# R> package.skeleton(name="jsonRPCviaMQ", code_files=c("jsonRPCviaMQ.R"), list=c("jsonRPCviaMQ.runOnce", "jsonRPCviaMQ.runForever", "jsonRPCviaMQ.runFor"))

# CHECKING/TESTING: running tests, ensuring the package structure is fine, run from the source's parent directory:
# R CMD check --no-multiarch jsonRPCviaMQ

# BUILDING, creating ZIP or tar.gz file for distribution:
# R CMD INSTALL --no-multiarch --build jsonRPCviaMQ




jsonRPCviaMQ.runOnce <- function
	###
	### Convenience method.
	###
	### Connect to a queue, check for a single message and execute if a valid message was received.
	### Exit after checking for 1 message.
	###
	(queue, host, queueType) {
	return(jsonRPCviaMQ.run(queue = queue, host = host, queueType = queueType, durationS = 1, waitForS = 1));
}


jsonRPCviaMQ.runForever <- function
	###
	### Convenience method.
	###
	### Connect to a queue, check for a single message and execute if a valid message was received.
	### Never exit, continue checking for messages indefinitely.
	### Sleep for 'waitForS' seconds between message checks.
	###
	(queue, host, queueType, waitForS = 60) {
	return(jsonRPCviaMQ.run(queue = queue, host = host, queueType = queueType, durationS = -1, waitForS = waitForS));
}


jsonRPCviaMQ.runFor <- function
	###
	### Convenience method.
	###
	### Connect to a queue, check for a single message and execute if a valid message was received.
	### Run for a specified duration, in seconds (i.e. 6hrs = 6*60*60).
	### Sleep for 'waitTimeS' seconds between message checks.
	###
	(queue, host, queueType, durationS, waitForS = 60) {
	return(jsonRPCviaMQ.run(queue = queue, host = host, queueType = queueType, durationS = durationS, waitForS = waitForS));
}






jsonRPCviaMQ.run = function
	###
	### The real logic
	###
	### Connect to a queue, check for a single message and execute if a valid message was received.
	### durationS indicates how many seconds to run this 'server' for.
	### waitForS indicates how long to 'sleep' between checks of the queue.
	### queueType indicates the type of queue to query, valid values are 'activeMQ' and 'rabbitMQ' as per https://code.google.com/p/r-message-queue/
	###
	### returns the number of messages processed.
	###
	(queue, ##<< name of queue to pull messages from
	host = "tcp://localhost:61616", ##<< server hosting the queue specified above, default is tcp://localhost:61616
	queueType = "activeMQ", ##<< type of queue, currently supports activeMQ and rabbitMQ
	durationS = -1, ##<< duration to run, in seconds, before exiting
	waitForS = 60 ##<< time to wait, in seconds, before checking the queue if no work was found during the previous check
	) {
		
		
	require(messageQueue);
	require(futile.logger);
	logger <- 'jsonRPCviaMQ';
	flog.debug("[jsonRPCviaMQ.run] run(queue=%s, host=%s, queueType=%s, durationS=%s, waitForS=%s)", queue, host, queueType, durationS, waitForS, name=logger);
	
	## print warning messages as we go
	options(warn=1);
	
	# only 3 significant digits
	options(digits.secs=3);
	
	start_time_seconds = as.numeric(Sys.time());
	cur_time_seconds = start_time_seconds + 0.99;
	loops = 0;
	messages_processed = 0;

	
	
	# setup the consumer queue
	flog.trace("[jsonRPCviaMQ.run] setting up queue consumer", name=logger);
	request.queue = messageQueue.factory.getConsumerFor(host, queue, queueType);

	
	
	# loop for a certain duration (or infinite if durationS == -1)
	while (durationS == -1 || (cur_time_seconds - start_time_seconds < durationS)) {
		loops <- loops + 1;
		flush.console();
		flog.trace("[jsonRPCviaMQ.run] looping, duration so far: %s, limit: %s", cur_time_seconds - start_time_seconds, durationS, name=logger);

		
		# make sure we can continue to process messages if a few cause errors
		tryCatch({
					
			# next message to process
			request.message = messageQueue.consumer.getNextText(request.queue);
			
			
			if (!is.null(request.message)) {
				flog.debug("[jsonRPCviaMQ.run] message received, processing...", name=logger);
				
				
				# process the request (first element of list, which is the RPC body)
				response = jsonRPCviaMQ.executeJsonRPC(request.message[['value']]);
				messages_processed <- messages_processed + 1;
				flog.debug("[jsonRPCviaMQ.run] response: %s", response, name=logger);
	
				
				# is there a replyto queue?
				if (!is.null(request.message[['replyTo']])) {
					response.queue = messageQueue.factory.getProducerFor(host, request.message[['replyTo']], queueType);
					status = messageQueue.producer.putText(producer=response.queue, text=response, correlationId=request.message[['correlationId']]);
					messageQueue.producer.close(response.queue);
				} else {
					flog.error("[jsonRPCviaMQ.run] No replyTo queue specified for msg %s", request.message[['value']], name=logger);
					flog.error("[jsonRPCviaMQ.run] -- response msg: %s", response, name=logger);
				}
				
			} else {
				flog.debug("[jsonRPCviaMQ.run] No message available, sleeping for %ss...", waitForS, name=logger);
				
				# ensure logging messages are written, sometimes they are buffered
				flush.console();
				Sys.sleep(waitForS)
			}
		
		
		},
		error = function (err)
		{
			flog.error("[jsonRPCviaMQ.run] Unexplained error reading/processing rpc message, error: %s, sleeping for %ss", err, waitForS, name=logger);
			
			# ensure logging messages are written, sometimes they are buffered
			flush.console();
			Sys.sleep(waitForS)
		});
		cur_time_seconds <- as.numeric(Sys.time());
	}
	flog.debug("[jsonRPCviaMQ.run] (done) looping, loop count: %s, messages processed: %s, duration: %s", loops, messages_processed, (cur_time_seconds - start_time_seconds), name=logger);
	flush.console();

	# close the consumer queue
	messageQueue.consumer.close(request.queue);
	flog.trace("[jsonRPCviaMQ.run] closed queue consumer", name=logger);

	return(messages_processed);
}



jsonRPCviaMQ.executeJsonRPC = function
	###
	### Execute a single RPC or batch of RPCs.
	###
	### This method will decode the string and call 'executeRPC' for each valid RPC call found.
	###
	### Input is the raw jsonRPC formatted request.
	### Output is the raw jsonRPC formatted response.
	###
	(rpcRequestString ##<< unparsed string in json-rpc format
	) {


	require(RJSONIO);
	require(futile.logger);
	logger <- 'jsonRPCviaMQ';
	
	# default response
	response = '{"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request (generic)"}, "id": NULL}';

	
	# default response
	exec_time = Sys.time()
	flog.debug("executeJsonRPC, request: %s, type: %s, (%s)", rpcRequestString, typeof(rpcRequestString), typeof(as.character(rpcRequestString)), name=logger);

	
	# convert input string into JSON
	calls = tryCatch(
		{  
			calls = RJSONIO::fromJSON(content=rpcRequestString);
			
			# return calls object
			calls;
		},
		error = function (err)
		{
			flog.error("error parsing json rpc request, error: %s", err, name=logger);
			calls = NULL;
			
			# return calls object
			calls;
		}
	)

	# half the time, calls is a character object - not sure why, but i can convert it back
	if (!is.null(calls) && is.character(calls)) {
		calls = as.list(calls);
	}

	flog.debug(" before processing calls, is.null(calls): %s", is.null(calls), name=logger);
	# no requests...
	if (is.null(calls)) {
		flog.debug(" calls is null.", name=logger);
		
		# jsonrpc 2.0 spec says to return error code -32700 on a parse error: http://www.jsonrpc.org/specification
		error_message = paste("Parse error.  Original request:", rpcRequestString, ", executed at: ", exec_time, sep="");
		response = jsonRPCviaMQ.toJsonRpcError(id = NULL, error_code = -32700, error_message);
		
	} else if (length(calls) == 0) {
		flog.debug(" calls length is 0", name=logger);
		
		# jsonrpc 2.0 spec says to return error code -32600 on an invalid request error: http://www.jsonrpc.org/specification
		error_message = paste("Invalid request.  Original request:", rpcRequestString, ", executed at: ", exec_time, sep="");
		response = jsonRPCviaMQ.toJsonRpcError(id = NULL, error_code = -32600, error_message);
		
	# 1 or more requests
	} else {
		
		results <- list();

		# BATCH of calls: it's a list, NOT a name/value list, and has at least 1 element
		if (is.list(calls) && is.null(names(calls)) && length(calls) > 0){
	
			index <- 1;
			# execute each call individually...
			for (call in calls) {
				flog.debug("    multi - method[%s]: %s, length: %s, id: %s", index, call[['method']], length(call), call[['id']], name=logger);
				
				# execute the remote procedure call, return the result..
				result = jsonRPCviaMQ.executeRPC(call, exec_time);
				results[[index]] <- result;
				index <- index+1;
			}
	
		
		# SINGLE call: it's name/value list with at least 3 elements
		} else if (is.list(calls) && !is.null(names(calls)) && length(calls) > 2) {
			flog.debug("    single - method: %s, length: %s", calls[['method']], length(calls), name=logger);
			
			# execute the remote procedure call, return the result..
			result = jsonRPCviaMQ.executeRPC(calls, exec_time);
			results[[1]] <- result;
		}
	
		
		
		# convert result to a json string
	
	
		# single results will be in a name/value list
		if (length(results) == 1) {
			response = RJSONIO::toJSON(result, pretty=FALSE, simplify=FALSE, simplifyWithNames = FALSE, digits=50, collapse=" ");
			flog.debug(" single response: %s ", response, name=logger);
			
		# if a multi result, list
		} else {
			response = RJSONIO::toJSON(results, pretty=FALSE, simplify=FALSE, simplifyWithNames = FALSE, digits=50, collapse=" ");
			flog.debug(" multiple results: %s ", response, name=logger);
		}
	}

	return(response);
}


jsonRPCviaMQ.executeRPC = function
	###
	### Execute a single RPC from an R object structured like a jsonrpc object
	### Returns a list with all parameters needed for a jsonrpc response
	###
	### Error codes outlined here: http://www.jsonrpc.org/specification
	### 
	(call, ##<< structured variable representing the jsonrpc call
	exec_time) {


	require(RJSONIO);
	require(futile.logger);
	logger <- 'jsonRPCviaMQ';

	
	# do we have a valid rpc request?
	if (!is.null(call) && !is.null(call[['method']]) && !is.null(call[['jsonrpc']]) && call[['jsonrpc']] == "2.0") {
		
		# if a method was specified, and it exists
		if (!is.null(call[['method']]) && exists(call[['method']])) {
			
			result <- tryCatch({
						
				# deal with an empty parameter list
				if ('params' %in% names(call)) {
					params <- as.list(call[['params']]);
				} else {
					params <- list();
				}
				
				
				# execute the method
				flog.info("executing method: %s(%s)", call[['method']], paste(names(params), "='", params,"'", sep="", collapse=", "));
				exec_result = do.call(call[['method']], params);
				flog.info("   done, result: %s", exec_result, name=logger);
				
				# build an object that holds all the fields a response would hold...
				result_success = list(jsonrpc="2.0", result=exec_result, id=call[['id']]);
#				response_success = jsonRPCviaMQ.toJsonRpcSuccess(id = request[['id']], result = exec_result);
				
				
				# successful response
				result_success;
				
				
			}, error = function(err) {
				flog.error("", name=logger);
				flog.error("", name=logger);
				flog.error("error executing method", name=logger);
				flog.error(paste(err), name=logger);
				flog.error("", name=logger);
				flog.error("", name=logger);
				error_message = paste("Invalid method parameters (or error executing): '", call[['method']], "', executed at: ", exec_time, sep="");
				
				result_error = list(jsonrpc="2.0", error=list(code=-32602, message=error_message), id=call[['id']]);
#				response_error = jsonRPCviaMQ.toJsonRpcError(id = call[['id']], error_code = -32602, error_message);
			
				# error response
				result_error;
			});
	
		} else {
			flog.warn("method doesn't exist: %s", call[['method']], name=logger);
			
			emessage = paste("Method not found: '", call[['method']], "', executed at: ", exec_time, sep="");
			result = list(jsonrpc="2.0", error=list(code=-32601, message=emessage), id=call[['id']]);
			#response = jsonRPCviaMQ.toJsonRpcError(id = call[['id']], error_code = -32601, error_message = emessage);
		}

		
		
	# invalid RPC request
	} else {
		emessage = "Unknown error.";
		mid = NULL;
		if (is.null(call)) {
			emessage = "Invalid request (empty).";
		} else if (is.null(call[['jsonrpc']]) || call[['jsonrpc']] != "2.0") {
			emessage = "Invalid request: jsonrpc version, expected 2.0.";
			mid = call[['id']];
		} else if (is.null(call[['method']])) {
			emessage = "Invalid request: missing method parameter.";
			mid = call$id;
		}
		
		
		flog.error(emessage, name=logger);
		error_message = paste(emessage, " for method: ", call[['method']], ", executed at: ", exec_time, sep="");
		result = list(jsonrpc="2.0", error=list(code = -32600, message=error_message), id=mid);
#		response = jsonRPCviaMQ.toJsonRpcError(id = mid, error_code = -32600, error_message);
	}


	flog.debug("executeRPC complete", name=logger);
	return(result);
}





jsonRPCviaMQ.toJsonRpcError = function
	###
	### Helper method
	###
	### create a JSON RPC error message
	###
	(id, error_code, error_message, version = "2.0") {
	require(RJSONIO);
	
	# build the message
	msg = list();
	msg$jsonrpc = version;
	msg$id = id;

	# build the error
	error = list();
	error$code = error_code;
	error$message = error_message;
	msg$error = error;
	
	
	# 'digits=X' ensures we aren't losing precision on floating point numbers
	jsonMsg <- RJSONIO::toJSON(msg, pretty=TRUE, simplify=FALSE, simplifyWithNames = FALSE, digits=50, collapse=" ");
	return(jsonMsg);
}



jsonRPCviaMQ.toJsonRpcSuccess = function
	###
	### Helper method
	###
	### create a JSON RPC success message
	###
	(id, result = NULL, version="2.0") {
	require(RJSONIO);
	
	msg = list();
	msg$jsonrpc = version;
	msg$id = id;

	msg$result = result;

	# 'digits=X' ensures we aren't losing precision on floating point numbers
	jsonMsg <- RJSONIO::toJSON(msg, pretty=TRUE, simplify=FALSE, simplifyWithNames = FALSE, digits=50, collapse=" ");
	return(jsonMsg);
}


jsonRPCviaMQ.echo = function
	###
	### Echo a request to the response queue.  This is a handy method for testing end-to-end.
	###
	(text) {
	return(text);
}

jsonRPCviaMQ.who = function
	###
	### Echo a request to the response queue.  This is a handy method for testing end-to-end.
	###
	(sleepS=10 ##<< how long to sleep after indicating that this machine is listening (allows other machines to respond)
	) {
		
	response <- paste(Sys.info()["login"], " on ", Sys.info()["nodename"], " is waiting for work, sleeping for ",sleepS,"s", sep="");
	Sys.sleep(sleepS)
	return(response);
}
	
	