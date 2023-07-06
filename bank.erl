-module(bank).
-export([start_bank/3]).

start_bank(Bank,Capacity,MoneyId) ->
        % io:format("Bank Up:~p ~p ~p~n",[Bank,Capacity,MoneyId]),
        send_receive_request(Bank,Capacity,MoneyId).
       
    
        send_receive_request(Bank,Capacity,MoneyId)->
            receive
                {CustomerProcessID,Customer,LoanObjective} ->
                    % io:format("ProcessID: ~p Customer Name: ~p Loan Request:~p ~n",[CustomerProcessID,Customer,LoanObjective]),
                    Status= if LoanObjective > Capacity -> 
                            "Denied";
                            true->"Approved"
                            end,
                    case Status of
                        "Approved"->
                            NewCapacity=Capacity-LoanObjective,
                            % io:format("New: Capacity of ~p is ~p~n",[Bank,NewCapacity]),
                            %Send Approval Message to the requesting customer.
                            CustomerProcessID ! {Status},
                            %Send loan approval message to the money process.
                            MoneyId ! {Status, "Bank_Message", Customer, LoanObjective, Bank,self()},
                            send_receive_request(Bank,NewCapacity,MoneyId);
                        _ ->
                            %Send rejected message to the requesting customer.
                            CustomerProcessID ! {Status},
                            %Send loan denied message to the money process.
                            MoneyId ! {Status, "Bank_Message", Customer, 0, Bank,self()},
                            send_receive_request(Bank, Capacity, MoneyId)
                    end
                    
            % after
            %     15000->
            %         io:format("Timeout  ~p ~n",[Bank]),
            %         send_receive_request(Bank,Capacity,MoneyId)
            end.
