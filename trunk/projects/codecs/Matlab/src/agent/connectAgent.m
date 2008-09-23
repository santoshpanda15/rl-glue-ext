function connectAgent(theAgent)
    global p__rlglueAgentStruct;
    
    if (exist('p__rlglueAgentStruct'))
        if exist('p__rlglueAgentStruct.network')
            disconnectAgent();
        end
    end
    
    p__rlglueAgentStruct.theAgent=theAgent;
    host='localhost';
    port=4096;
    timeout=60;
    
    
    fprintf(1,'Connecting to rl_glue at host: %s on port %d\n', host, port);

    p__rlglueAgentStruct.network=org.rlcommunity.rlglue.codec.network.Network;
    p__rlglueAgentStruct.network.connect(host,port,timeout);

    p__rlglueAgentStruct.network.clearSendBuffer();
    p__rlglueAgentStruct.network.putInt(org.rlcommunity.rlglue.codec.network.Network.kAgentConnection);
    p__rlglueAgentStruct.network.putInt(0);% No body to this packet
    p__rlglueAgentStruct.network.flipSendBuffer();
    p__rlglueAgentStruct.network.send();
end