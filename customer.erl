-module(customer).
-export([start_customer/4]).

start_customer(Customer,Objective,MoneyId,BankDict) ->
        % timer:sleep(5000),
        % io:format("Process Up:~p ~p ~p~n",[Customer,Objective,MoneyId]),
        BankList=dict:to_list(BankDict),
        TotalLoanAmount=0,
        TotalLoanAmountResult=borrow_from_bank(Customer,Objective,MoneyId,BankList,TotalLoanAmount),
        % io:format(">>>>>>>>>>> ~p received total loan of ~p~n",[Customer,TotalLoanAmountResult]),
        MoneyId ! {"Finished","Customer_Message",Customer,Objective,"",TotalLoanAmountResult}.
        
        borrow_from_bank(Customer,Objective,MoneyId,BankList,TotalLoanAmount)->
                RandomIndex=rand:uniform(length(BankList)),
                % io:format("Bank List:~p",BankList),
                {BankProcessId,{BankName,Capacity,LoanDispatch}}=lists:nth(RandomIndex,BankList),
                % io:format(">>Id: ~p Name: ~p ~n",[BankProcessId,BankName]),
                LoanRequest=rand:uniform(erlang:min(Objective,50)),
                % timer:sleep(200),
                %Send Loan Request to the Banks.
                BankProcessId ! {self(),Customer,LoanRequest},
                %Send an alert message to the money Process.
                MoneyId !{"","Customer_Message",Customer,LoanRequest,BankName,0},
                receive
                        %Loan Approved Case
                        {Status} when Status =:= "Approved" ->
                                % io:format("Loan has been approved~n"),
                                %deduct the loan that has been approved.
                                UpdatedTotalLoanAmount=TotalLoanAmount+LoanRequest,
                                NewObjective=Objective-LoanRequest,
                                % io:format("~p New Objective is: ~p~n",[Customer,NewObjective]),
                                if 
                                        NewObjective > 0 andalso length(BankList)>0 ->
                                                borrow_from_bank(Customer,NewObjective,MoneyId,BankList,UpdatedTotalLoanAmount);
                                        true ->
                                                UpdatedTotalLoanAmount
                                end;
                        %Loan Denied Case
                        {Status}->
                                % io:format("Loan has been denied~n"),
                                UpdatedBankList = lists:delete({BankProcessId, {BankName,Capacity,LoanDispatch}}, BankList),
                                if 
                                        Objective > 0 andalso length(UpdatedBankList)>0 ->
                                                borrow_from_bank(Customer,Objective,MoneyId,UpdatedBankList,TotalLoanAmount);
                                        true ->
                                                TotalLoanAmount
                                end
                end.



% -module(customer_).
% -export([process1/0]).

% process1()->
%     receive
%         {From,MessageRecieved} ->
%             io:format("Recvied Message by process1: ~p~n",[MessageRecieved]),
%             From ! {self(),"process1 says it works"}
%     end.