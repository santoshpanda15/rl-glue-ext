function shouldQuit=runAgentLoop()
    global p__rlglueAgentStruct;
%This is all just copied in from ClientAgent in the Java codec    
    
    shouldQuit=false;
    network=p__rlglueAgentStruct.network;
    theAgent=p__rlglueAgentStruct.theAgent;
    network.clearRecvBuffer();
    recvSize = network.recv(8) - 8; %// We may have received the header and part of the payload
                                    %// We need to keep track of how much of the payload was recv'd

    agentState = network.getInt(0);
    dataSize = network.getInt(org.rlcommunity.rlglue.codec.network.Network.kIntSize);

    remaining = dataSize - recvSize;
    if remaining < 0
        fprintf(1,'Remaining was less than 0!\n');
    end

    amountReceived = network.recv(remaining);			

    network.flipRecvBuffer();

    %// We have already received the header, now we need to discard it.
    network.getInt();
    network.getInt();

    switch(agentState)
        
    case {org.rlcommunity.rlglue.codec.network.Network.kAgentInit}
		taskSpec = network.getString();
		theAgent.agent_init(taskSpec);

		network.clearSendBuffer();
		network.putInt(org.rlcommunity.rlglue.codec.network.Network.kAgentInit);
		network.putInt(0); % No data following this header

    case {org.rlcommunity.rlglue.codec.network.Network.kAgentStart}
		observation = network.getObservation();
		action = theAgent.agent_start(observation);
		size = org.rlcommunity.rlglue.codec.network.Network.sizeOf(action); 
		network.clearSendBuffer();
		network.putInt(org.rlcommunity.rlglue.codec.network.Network.kAgentStart);
		network.putInt(size);
		network.putAction(action);

    case {org.rlcommunity.rlglue.codec.network.Network.kAgentStep}
		reward = network.getDouble();
		observation = network.getObservation();
		action = theAgent.agent_step(reward, observation);

		size = org.rlcommunity.rlglue.codec.network.Network.sizeOf(action); 
		network.clearSendBuffer();
		network.putInt(org.rlcommunity.rlglue.codec.network.Network.kAgentStep);
		network.putInt(size);
		network.putAction(action);

    case {org.rlcommunity.rlglue.codec.network.Network.kAgentEnd}
		reward = network.getDouble();
		theAgent.agent_end(reward);

		network.clearSendBuffer();
		network.putInt(org.rlcommunity.rlglue.codec.network.Network.kAgentEnd);
		network.putInt(0); %No data in this packet

    case {org.rlcommunity.rlglue.codec.network.Network.kAgentCleanup}
		theAgent.agent_cleanup();
		network.clearSendBuffer();
		network.putInt(org.rlcommunity.rlglue.codec.network.Network.kAgentCleanup);
		network.putInt(0); % No data in this packet


    case {org.rlcommunity.rlglue.codec.network.Network.kAgentMessage}
		message = network.getString();
		reply = theAgent.agent_message(message);
		
		network.clearSendBuffer();
		network.putInt(org.rlcommunity.rlglue.codec.network.Network.kAgentMessage);
		network.putInt(org.rlcommunity.rlglue.codec.network.Network.sizeOf(reply));
		network.putString(reply);

    case {org.rlcommunity.rlglue.codec.network.Network.kRLTerm}
        disconnectAgent();
        shouldQuit=true;
        return;
   otherwise
        fprintf(2,'Unknown state in runAgentLoop %d\n',agentState);
        exit(1);
    end
    
    network.flipSendBuffer();
    network.send();
end