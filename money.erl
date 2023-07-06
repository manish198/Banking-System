-module(money).
-export([start/1]).
-import (customer,[start_customer/4]).
start(Args) ->
    CustomerFile=lists:nth(1,Args),
    BankFile=lists:nth(2,Args),

    {ok,CustomerInfo}=file:consult(CustomerFile),
    {ok,BankInfo}=file:consult(BankFile),
    io:format("**The financial market is opening for the day** ~n Starting transaction log.~n"),
    
    %spawn method for the customer process.
    BankDict=spawn_bank_processes(BankInfo),
    %spawn method for the customer process.
    CustomerDict=spawn_customer_processes(CustomerInfo,BankDict),
    TotalNumberOfFinalResult=0,
    TotalCustomer=length(CustomerInfo),
    %Infinite loop to listen to reply from the banks and the customers.
    receive_loop(TotalNumberOfFinalResult,TotalCustomer,BankDict,CustomerDict).
    
    %this will get executed when totalNumber of final result reaches the number of total customer.
    receive_loop(TotalNumberOfFinalResult, TotalCustomer,BankDict,CustomerDict) when TotalNumberOfFinalResult >= TotalCustomer ->
        io:format("~n ************Banking Reports*********** ~n Customers:~n"),
        print_customer_result(CustomerDict),
        io:format("Banks:~n"),
        print_bank_result(BankDict);

    %Reveicing loop method
    receive_loop(TotalNumberOfFinalResult,TotalCustomer,BankDict,CustomerDict)->
        receive
        %Received Message from the Customer Status other than finished.
        {Status,SenderType,Customer,LoanRequest,BankName,TotalLoanAmount} when SenderType =:= "Customer_Message",Status=:="Finished"->
            %io:format("^^^^^^^^^^^^~p requested: ~p and recieved a loan of: ~p ^^^^^^^^^^^^^^ ~n",[Customer,LoanRequest,TotalLoanAmount]),
             NewNumberOfFinalResult=TotalNumberOfFinalResult+1,
             UpdatedCustomerDict = dict:store(Customer, {LoanRequest, TotalLoanAmount}, CustomerDict),
             receive_loop(NewNumberOfFinalResult,TotalCustomer,BankDict,UpdatedCustomerDict);
        %Received Message from the Customer Status other than finished.
        {Status,SenderType,Customer,LoanRequest,BankName,TotalLoanAmount} when SenderType =:= "Customer_Message" ->
             io:format("? ~p requests a loan of ~p dollor(s) from the ~p bank~n",[Customer,LoanRequest,BankName]),
             receive_loop(TotalNumberOfFinalResult,TotalCustomer,BankDict,CustomerDict);
            
        %Received Message from the Banks.
        {Status,SenderType,Customer,LoanRequest,BankName,BankId} when SenderType =:= "Bank_Message",Status=:="Approved"->
             io:format("$ The ~p bank  ~p a loan of ~p dollar(s)  to ~p ~n",[BankName,Status,LoanRequest,Customer]),
             {BankName, Capacity, LoanDispatched} = dict:fetch(BankId, BankDict),
             UpdatedBankDict = dict:store(BankId, {BankName, Capacity, LoanDispatched + LoanRequest}, BankDict),
            %  io:format("$ The ~p bank approves/denies a loan of ~p dollor(s) to ~p ~n",[BankName,LoanRequest,Customer]),
            receive_loop(TotalNumberOfFinalResult,TotalCustomer,UpdatedBankDict,CustomerDict);
        
        {Status,SenderType,Customer,LoanRequest,BankName,BankId}->
            io:format("$ The ~p bank  ~p a loan of ~p dollar(s)  to ~p ~n",[BankName,Status,LoanRequest,Customer]),
            %  io:format("$ The ~p bank approves/denies a loan of ~p dollor(s) to ~p ~n",[BankName,LoanRequest,Customer]),
            receive_loop(TotalNumberOfFinalResult,TotalCustomer,BankDict,CustomerDict)
        
        end.

    spawn_bank_processes(BankInfo) ->
        loop_bank(BankInfo,dict:new()).

    loop_bank([],BankDict) ->  % Base case: empty list
        BankDict;
    loop_bank([{Bank, Capacity} | Rest],BankDict) ->  % Recursive case: process head and iterate over tail
        BankPid=spawn(bank,start_bank,[Bank,Capacity,self()]),
        UpdatedBankDict=dict:store(BankPid,{Bank,Capacity,0},BankDict),
        loop_bank(Rest,UpdatedBankDict).
    
    
    
    spawn_customer_processes(CustomerInfo,BankDict) ->
        loop_customer(CustomerInfo,BankDict,dict:new()).

    loop_customer([],BankDict,CustomerDict) ->  % Base case: empty list
        CustomerDict;

    loop_customer([{Customer, Objective} | Rest],BankDict,CustomerDict) ->  % Recursive case: process head and iterate over tail
        % io:format("I was here"),
        % io:format("Customer Details: ~p ~p~n",[Customer,Value]),
        spawn(customer,start_customer,[Customer,Objective,self(),BankDict]),
        UpdatedCustomerDict=dict:store(Customer,{Objective,0}, CustomerDict),
        loop_customer(Rest,BankDict,UpdatedCustomerDict).

    %To display customer report.
    print_customer_result(CustomerDict)->
        print_customer_final_result(dict:to_list(CustomerDict),0,0).

    print_customer_final_result([],LoanRequestSum,TotalLoanAmountSum)->
        io:format("---------------------------------------~n  Total:objective ~p, received ~p~n",[LoanRequestSum,TotalLoanAmountSum]);

    print_customer_final_result([{Customer,{LoanRequest,TotalLoanAmount}} | Rest],LoanRequestSum,TotalLoanAmountSum)->
        io:format("~p: objective: ~p, received:~p ~n ",[Customer,LoanRequest,TotalLoanAmount]),
        NewLoanRequestSum=LoanRequestSum+LoanRequest,
        NewTotalLoanAmountSum=TotalLoanAmountSum+TotalLoanAmount,       
        print_customer_final_result(Rest,NewLoanRequestSum,NewTotalLoanAmountSum).

    %To display bank report.
    print_bank_result(BankDict)->
        print_bank_final_result(dict:to_list(BankDict),0,0).

    print_bank_final_result([],TotalLoanCapacity,TotalLoanGiven)->
        io:format("---------------------------------------~n  Total:original ~p, loaned ~p~n",[TotalLoanCapacity,TotalLoanGiven]);

    print_bank_final_result([{BankId,{Bank,LoanCapacity,LoanDispatched}} | Rest],TotalLoanCapacity,TotalLoanGiven)->
        io:format("~p: original: ~p, balance:~p ~n ",[Bank,LoanCapacity,LoanCapacity-LoanDispatched]),
        NewTotalLoanCapacity=TotalLoanCapacity+LoanCapacity,
        NewTotalLoanGiven=TotalLoanGiven+LoanDispatched,       
        print_bank_final_result(Rest,NewTotalLoanCapacity,NewTotalLoanGiven).

            % receive
            % {CustomerProcessID,Customer,Message}->
            %     io:format("ID ~p~n",[CustomerProcessID]),
            %     io:format("Customer:~p Message: ~p~n",[Customer,Message])
            % end.



% -module (money).
% -export ([start/0]).
% -import (customer,[process1/0]).

% start()->
%     Process1=spawn(customer,process1,[]),
%     Process1 ! {self(),hello},
%     receive
%         {Process1,MessageFromOne}->
%             io:format("This is a message from one: ~p~n",[MessageFromOne])
%     end.

