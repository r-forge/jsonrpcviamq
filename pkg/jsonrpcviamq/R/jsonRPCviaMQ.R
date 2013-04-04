##
# Set of methods monitor the specified message queue for JSON RPC calls.
#
# Includes jsonRPCviaMQ.echo method for testing.
#
# Error codes outlined here - http://www.jsonrpc.org/specification
# futile.logger outlined here - http://www.r-bloggers.com/better-logging-in-r-aka-futile-logger-1-3-0-released/
#
# TODO:
# 1.  batch RPC calls.
#
# author: Jesse Ross (jr634 at cornell)
# date: 3/21/13
#
# modifier: Matt MacGillivray (msm336 at cornell)
##


##
# Convenience method.
#
# Connect to a queue, check for a single message and execute if a valid message was received.
# Exit after checking for 1 message.
#
jsonRPCviaMQ.runOnce = function(queue, host, queueType) {
	return(jsonRPCviaMQ.run(queue = queue, host = host, queueType = queueType, durationS = 1, waitForS = 1));
}


##
# Convenience method.
#
# Connect to a queue, check for a single message and execute if a valid message was received.
# Never exit, continue checking for messages indefinitely.
# Sleep for 'waitForS' seconds between message checks.
#
jsonRPCviaMQ.runForever = function(queue, host, queueType, waitForS = 60) {
	return(jsonRPCviaMQ.run(queue = queue, host = host, queueType = queueType, durationS = -1, waitForS = waitForS));
}


##
# Convenience method.
#
# Connect to a queue, check for a single message and execute if a valid message was received.
# Run for a specified duration, in seconds (i.e. 6hrs = 6*60*60).
# Sleep for 'waitTimeS' seconds between message checks.
#
jsonRPCviaMQ.runFor = function(queue, host, queueType, durationS, waitForS = 60) {
	return(jsonRPCviaMQ.run(queue = queue, host = host, queueType = queueType, durationS = durationS, waitForS = waitForS));
}






##
# The real logic
#
# Connect to a queue, check for a single message and execute if a valid message was received.
# durationS indicates how many seconds to run this 'server' for.
# waitForS indicates how long to 'sleep' between checks of the queue.
# queueType indicates the type of queue to query, valid values are 'activeMQ' and 'rabbitMQ' as per https://code.google.com/p/r-message-queue/
#
# returns the number of messages processed.
#
#jsonRPCviaMQ.run = function (requestQueue = "R_RF_requestQueue", responseQueue = "R_RF_responseQueue",
#                                  mqHostPort = "tcp://localhost:61616", mqType = "activeMQ", sleepS = 60) {
jsonRPCviaMQ.run = function(queue, host = "tcp://localhost:61616", queueType = "activeMQ", durationS = -1, waitForS = 60) {
	require(messageQueue);
	require(futile.logger);
	logger <- 'jsonRPCviaMQ';
	flog.debug("[jsonRPCviaMQ.run] run(queue=%s, host=%s, queueType=%s, durationS=%s, waitForS=%s)", queue, host, queueType, durationS, waitForS, name=logger);
	
	start_time_seconds = Sys.time();
	cur_time_seconds = start_time_seconds + 0.99;
	loops = 0;
	messages_processed = 0;

	
	
	# setup the consumer queue
	flog.trace("[jsonRPCviaMQ.run] setting up queue consumer", name=logger);
	request.queue = messageQueue.factory.getConsumerFor(host, queue, queueType);

	
	
	# loop for a certain duration (or infinite if durationS == -1)
	while (durationS == -1 || (cur_time_seconds - start_time_seconds < durationS)) {
		loops <- loops + 1;
		flog.trace("[jsonRPCviaMQ.run] looping, duration so far: %s", (cur_time_seconds - start_time_seconds), name=logger);

		
		# make sure we can continue to process messages if a few cause errors
		tryCatch({
					
			# next message to process
			request.message = messageQueue.consumer.getNextText(request.queue);
			
			
			if (!is.null(request.message)) {
				flog.trace("[jsonRPCviaMQ.run] decoding message...", name=logger);
				
				
				# process the request (first element of list, which is the RPC body)
				response = jsonRPCviaMQ.executeRPC(request.message[['value']]);
				messages_processed <- messages_processed + 1;
				flog.debug("[jsonRPCviaMQ.run] response: %s",response, name=logger);
	
				
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
				flog.trace("[jsonRPCviaMQ.run] No message available, sleeping...", name=logger);
				Sys.sleep(waitForS)
			}
		
		
		},
		error = function (err)
		{
			flog.error("[jsonRPCviaMQ.run] Unexplained error reading/processing rpc message, error: %s", err, name=logger);
			Sys.sleep(waitForS)
		});
		cur_time_seconds <- Sys.time();
	}
	flog.debug("[jsonRPCviaMQ.run] (done) looping, loop count: %s, messages processed: %s, duration: %s", loops, messages_processed, (cur_time_seconds - start_time_seconds), name=logger);
	

	# close the consumer queue
	messageQueue.consumer.close(request.queue);
	flog.trace("[jsonRPCviaMQ.run] closed queue consumer", name=logger);
	
	return(messages_processed);
}




##
# Execute the passed in JSON RPC call.
# Returns a json-rpc response.
#
# Error codes outlined here: http://www.jsonrpc.org/specification
#
jsonRPCviaMQ.executeRPC = function(request) {
	require(RJSONIO);
	require(futile.logger);
	logger <- 'jsonRPCviaMQ';
	
	# default response
	response = '{"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request (generic)"}, "id": null}';
	exec_time = Sys.time()
	flog.debug("executeRPC, request: %s", request, name=logger);

	
	# parse the request
	request = tryCatch(
		{  
			fromJSON(request);
		},
		error = function (err)
		{
			flog.error("error parsing json rpc request, error: %s", err, name=logger);
			error_message = paste("Parse error.  Original request:", request, ", executed at: ", exec_time, "error message: ", err, sep="");
			
			# jsonrpc 2.0 spec says to return error code -32700 on a parse error: http://www.jsonrpc.org/specification
			response = jsonRPCviaMQ.toJsonRpcError(id = NULL, error_code = -32700, error_message);
		}
	)
	flog.debug("executeRPC, post tryCatch", name=logger);

	
	# do we have a valid rpc request?
	if (!is.null(request) && !is.null(request[['method']]) && !is.null(request[['jsonrpc']]) && request[['jsonrpc']] == "2.0") {
		
		# if a method was specified, and it exists
		if (!is.null(request[['method']]) && exists(request[['method']])) {
			
			response <- tryCatch({
						
				# deal with an empty parameter list
				if ('params' %in% names(request)) {
					params <- as.list(request[['params']]);
				} else {
					params <- list();
				}
				
				
				# execute the method
				exec_result = do.call(request[['method']], params);
				response_success = jsonRPCviaMQ.toJsonRpcSuccess(id = request[['id']], result = exec_result);
				
				flog.trace("   -- result: %s", response_success, name=logger);
				
				# successful response
				response_success;
				
				
			}, error = function(err) {
				flog.error("", name=logger);
				flog.error("", name=logger);
				flog.error("error executing method", name=logger);
				flog.error(paste(err), name=logger);
				flog.error("", name=logger);
				flog.error("", name=logger);
				error_message = paste("Invalid method parameters (or error executing): '", request[['method']], "', executed at: ", exec_time, sep="");
				response_error = jsonRPCviaMQ.toJsonRpcError(id = request[['id']], error_code = -32602, error_message);
			
				# error response
				response_error;
				
			});
	
		} else {
			flog.warn("method doesn't exist: %s", request[['method']], name=logger);
			
			emessage = paste("Method not found: '", request[['method']], "', executed at: ", exec_time, sep="");
			response = jsonRPCviaMQ.toJsonRpcError(id = request[['id']], error_code = -32601, error_message = emessage);
		}

		
		
	# invalid RPC request
	} else {
		emessage = "Unknown error.";
		mid = NULL;
		if (is.null(request)) {
			emessage = "Invalid request (empty).";
		} else if (is.null(request[['jsonrpc']]) || request[['jsonrpc']] != "2.0") {
			emessage = "Invalid request: jsonrpc version, expected 2.0.";
			mid = request[['id']];
		} else if (is.null(request[['method']])) {
			emessage = "Invalid request: missing method parameter.";
			mid = request$id;
		}
		
		
		flog.error(emessage, name=logger);
		error_message = paste(emessage, " for method: ", request[['method']], ", executed at: ", exec_time, sep="");
		response = jsonRPCviaMQ.toJsonRpcError(id = mid, error_code = -32600, error_message);
	}


	flog.debug("executeRPC returning: %s", response, name=logger);
	return(response);
}



##
# Helper method
#
# create a JSON RPC error message
jsonRPCviaMQ.toJsonRpcError = function(id, error_code, error_message, version = "2.0") {
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
	jsonMsg <- toJSON(msg, pretty=TRUE, simplify=FALSE, simplifyWithNames = FALSE, digits=50);
	return(jsonMsg);
}

##
# Helper method
#
# create a JSON RPC success message
jsonRPCviaMQ.toJsonRpcSuccess = function(id, result = NULL, version="2.0") {
	require(RJSONIO);
	
	msg = list();
	msg$jsonrpc = version;
	msg$id = id;

	msg$result = result;

	# 'digits=X' ensures we aren't losing precision on floating point numbers
	jsonMsg <- toJSON(msg, pretty=TRUE, simplify=FALSE, simplifyWithNames = FALSE, digits=50);
	return(jsonMsg);
}


##
# Echo a request to the response queue.  This is a handy method for testing end-to-end.
#
jsonRPCviaMQ.echo = function(text) {
	return(response);
}

##
# Echo a request to the response queue.  This is a handy method for testing end-to-end.
#
jsonRPCviaMQ.who = function(text, sleepS) {
	response <- paste(Sys.info()["login"], " on ", Sys.info()["nodename"], " is waiting for work", sep="");
	Sys.sleep(sleepS)
	return(response);
}
	
	
