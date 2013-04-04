# https://github.com/hadley/devtools/wiki/Testing

# this allows tests to run without actually running an ActiveMQ server
host <- "vm://localhost?broker.persistent=false&broker.useJmx=false&jms.prefetchPolicy.queuePrefetch=1";
queue <- "amq-runOnce-test-queue";
replyTo <- "amq-runOnceReply-test-queue";
type <- "activeMQ";

context("runOnce");
require(RJSONIO);
require(futile.logger);
flog.threshold(TRACE, name="jsonRPCviaMQ");


test_that("can execute a single RPC statement", {
	request <- '{"jsonrpc": "2.0", "method": "Sys.time", "id": "67"}';
	
	# put the message on the queue for execution
	producer.queue = messageQueue.factory.getProducerFor(host, queue, type);
	status <- messageQueue.producer.putText(producer=producer.queue, text=request, correlationId = "111-222-333", replyToQueue=replyTo);

#	Sys.sleep(5);
	
	# for comparison
	time_before_request <- as.double(Sys.time());


	# execute
	msg_count = jsonRPCviaMQ.runOnce(queue, host, type);
	expect_equal(msg_count, 1, info=paste("actual number of messages processed: ",msg_count,sep=""));

#	Sys.sleep(5);

	# retrieve the response on the replyTo queue
	consumer.queue = messageQueue.factory.getConsumerFor(host, replyTo, type);
	response <- messageQueue.consumer.getNextText(consumer.queue);
	messageQueue.consumer.close(consumer.queue);
	
	expect_true(!is.null(response), info=paste("runOnce - Message is null."));
	
	robj <- fromJSON(response[['value']]);

	
	# result
	expect_equal(robj[['id']], '67');
	expect_equal(response[['correlationId']], '111-222-333');
	expect_true(is.double(robj[['result']]));
	expect_true(robj[['result']] >= time_before_request, info=paste("time start: ",time_before_request,", result: ",robj[['result']], sep=""));

	
	
	# close this last, because in memory broker deletes contents of queue if there are no references
	messageQueue.producer.close(producer.queue);
});



test_that("can fail gracefully", {
	request <- '{"jsonrpc": "2.0", "method": "Sys.time", "params": [1], "id": "72"}';
	
	flog.debug("can fail gracefully - start");
	
	# put the message on the queue for execution
	producer.queue = messageQueue.factory.getProducerFor(host, queue, type);
	status <- messageQueue.producer.putText(producer=producer.queue, text=request, correlationId = "222-333-444", replyToQueue=replyTo);
	flog.debug("can fail gracefully - produced message");

#	Sys.sleep(5);
	
	# for comparison
	time_before_request <- as.double(Sys.time());


	# execute
	msg_count = jsonRPCviaMQ.runOnce(queue, host, type);
	expect_equal(msg_count, 1, info=paste("actual number of messages processed: ",msg_count,sep=""));

#	Sys.sleep(5);

	# retrieve the response on the replyTo queue
	consumer.queue = messageQueue.factory.getConsumerFor(host, replyTo, type);
	response <- messageQueue.consumer.getNextText(consumer.queue);
	messageQueue.consumer.close(consumer.queue);
	
	expect_true(!is.null(response), info=paste("runOnce - Message is null."));
	
	robj <- fromJSON(response[['value']]);

	
	# result
	expect_equal(robj[['id']], '72');
	expect_equal(response[['correlationId']], '222-333-444');
	expect_false(is.double(robj[['result']]));
	expect_equal(robj[['error']][['code']], -32602);
	error_message_prefix <- "Invalid method";
	expect_equal(substr(robj[['error']][['message']],1,nchar(error_message_prefix)),error_message_prefix);
	flog.debug("can fail gracefully - end");
	
	
	
	# close this last, because in memory broker deletes contents of queue if there are no references
	messageQueue.producer.close(producer.queue);
});