
normalize_full(inform(full(var_BinID),var__From),var_BinID).

normalize_full(inform(full(var_BinID),var__Meta,var__From),var_BinID).

normalize_full(inform(full(var_BinID)),var_BinID).

normalize_full(full(var_BinID),var_BinID).

normalize_agree(inform(agree(var_Truck,var_BinID),var__From),var_Truck,var_BinID).

normalize_agree(inform(agree(var_Truck,var_BinID),var__Meta,var__From),var_Truck,var_BinID).

normalize_agree(inform(agree(var_Truck,var_BinID)),var_Truck,var_BinID).

normalize_agree(agree(var_Truck,var_BinID),var_Truck,var_BinID).

normalize_refuse(inform(refuse(var_Truck,var_BinID),var__From),var_Truck,var_BinID).

normalize_refuse(inform(refuse(var_Truck,var_BinID),var__Meta,var__From),var_Truck,var_BinID).

normalize_refuse(inform(refuse(var_Truck,var_BinID)),var_Truck,var_BinID).

normalize_refuse(refuse(var_Truck,var_BinID),var_Truck,var_BinID).

normalize_collected(inform(collected(var_Truck,var_BinID),var__From),var_Truck,var_BinID).

normalize_collected(inform(collected(var_Truck,var_BinID),var__Meta,var__From),var_Truck,var_BinID).

normalize_collected(inform(collected(var_Truck,var_BinID)),var_Truck,var_BinID).

normalize_collected(collected(var_Truck,var_BinID),var_Truck,var_BinID).

truck_pool([truck1,truck2,truck3]).

timeout_retry_cooldown_cycles(4).

refuse_retry_cooldown_cycles(6).

inflight_timeout_cycles(20).

max_dispatch_timeouts(5).

dispatch_delay_cycles(2).

cc_log_in(var_From,var_Payload):-format('Control center | IN from=~w payload=~w~n',[var_From,var_Payload]).

cc_send(var_To,var_Payload):-clause(agent(var_CC),var__),format('Control center | OUT to=~w payload=~w~n',[var_To,var_Payload]),a(message(var_To,var_Payload,var_CC)).

cc_send_collect(var_Truck,var_BinID):-clause(agent(var_CC),var__),cc_send(var_Truck,inform(collect(var_BinID),var_CC)).

cc_send_cleared(var_BinID):-clause(agent(var_CC),var__),cc_send(var_BinID,inform(cleared,var_CC)).

cc_log_status(var_BinID,var_Status,var_Template,var_Args):-clause(cc_last_status(var_BinID,var_Status),var__)->true;retractall(cc_last_status(var_BinID,var__)),assert(cc_last_status(var_BinID,var_Status)),format(var_Template,var_Args).

schedule_retry(var_BinID,timeout):-timeout_retry_cooldown_cycles(var_Cycles),retractall(retry_countdown(var_BinID,var__)),assert(retry_countdown(var_BinID,var_Cycles)).

schedule_retry(var_BinID,refused):-refuse_retry_cooldown_cycles(var_Cycles),retractall(retry_countdown(var_BinID,var__)),assert(retry_countdown(var_BinID,var_Cycles)).

schedule_dispatch_delay(var_BinID):-dispatch_delay_cycles(var_Cycles),retractall(dispatch_countdown(var_BinID,var__)),assert(dispatch_countdown(var_BinID,var_Cycles)).

start_inflight_timer(var_BinID):-retractall(inflight_countdown(var_BinID,var__)),inflight_timeout_cycles(var_Cycles),assert(inflight_countdown(var_BinID,var_Cycles)).

clear_inflight_timer(var_BinID):-retractall(inflight_countdown(var_BinID,var__)).

record_timeout(var_BinID,var_Count):-(clause(timeout_count(var_BinID,var_C0),var__)->var_C1 is var_C0+1;var_C1=1),retractall(timeout_count(var_BinID,var__)),assert(timeout_count(var_BinID,var_C1)),var_Count=var_C1.

clear_timeout_count(var_BinID):-retractall(timeout_count(var_BinID,var__)).

tick_retry_queue(dummy):-clause(retry_countdown(var_BinID,var_N),var__),var_N>0,var_N1 is var_N-1,retractall(retry_countdown(var_BinID,var__)),assert(retry_countdown(var_BinID,var_N1)),fail.

tick_retry_queue(dummy).

tick_dispatch_queue(dummy):-clause(dispatch_countdown(var_BinID,var_N),var__),var_N>0,var_N1 is var_N-1,retractall(dispatch_countdown(var_BinID,var__)),assert(dispatch_countdown(var_BinID,var_N1)),fail.

tick_dispatch_queue(dummy).

tick_inflight_watchdog(dummy):-clause(inflight(var_BinID),var__),clause(inflight_countdown(var_BinID,var_N),var__),var_N>0,var_N1 is var_N-1,retractall(inflight_countdown(var_BinID,var__)),assert(inflight_countdown(var_BinID,var_N1)),fail.

tick_inflight_watchdog(dummy):-clause(inflight(var_BinID),var__),clause(inflight_countdown(var_BinID,0),var__),record_timeout(var_BinID,var_TimeoutN),max_dispatch_timeouts(var_MaxTimeouts),(var_TimeoutN>=var_MaxTimeouts->cc_log_status(var_BinID,fallback(var_TimeoutN),'Control center | fallback: forcing completion for bin=~w after ~w timeouts~n',[var_BinID,var_TimeoutN]),cc_send(logger,inform(completed(timeout,var_BinID),var_CC)),cc_send_cleared(var_BinID),retractall(awaiting(var_BinID)),retractall(assigned_bin(var_BinID,var__)),retractall(bin_ready_for_collection(var_BinID)),clear_timeout_count(var_BinID);true),cc_log_status(var_BinID,timeout(var_TimeoutN),'Control center | timeout: no truck response for bin=~w, releasing inflight~n',[var_BinID]),retractall(inflight(var_BinID)),clear_inflight_timer(var_BinID),schedule_retry(var_BinID,timeout),fail.

tick_inflight_watchdog(dummy).

remove_seen([],var__,[]).

remove_seen([var_H|var_T],var_Seen,var_R):-member(var_H,var_Seen),remove_seen(var_T,var_Seen,var_R).

remove_seen([var_H|var_T],var_Seen,[var_H|var_R]):- \+member(var_H,var_Seen),remove_seen(var_T,var_Seen,var_R).

truck_busy(var_Truck):-clause(assigned_bin(var__,var_Truck),var__).

truck_busy(var_Truck):-clause(last_try(var_BinID,var_Truck),var__),clause(inflight(var_BinID),var__).

remove_busy([],[]).

remove_busy([var_H|var_T],var_R):-truck_busy(var_H),remove_busy(var_T,var_R).

remove_busy([var_H|var_T],[var_H|var_R]):- \+truck_busy(var_H),remove_busy(var_T,var_R).

random_pick(var_List,var_Pick):-length(var_List,var_L),var_L>0,random(0,var_L,var_N),nth0(var_N,var_List,var_Pick).

dispatch_request(var_BinID):- \+clause(bin_ready_for_collection(var_BinID),var__),cc_log_status(var_BinID,blocked_not_full,'Control center | blocked: bin=~w not full yet, collection skipped~n',[var_BinID]),clause(agent(var_CC),var__),cc_send(logger,inform(blocked_not_full(var_BinID),var_CC)),!.

dispatch_request(var_BinID):-clause(inflight(var_BinID),var__),!.

dispatch_request(var_BinID):-clause(assigned_bin(var_BinID,var__),var__),!.

dispatch_request(var_BinID):-truck_pool(var_AllTrucks),(clause(tried_trucks(var_BinID,var_Tried),var__)->true;var_Tried=[]),remove_seen(var_AllTrucks,var_Tried,var_Candidates0),(var_Candidates0=[]->retractall(tried_trucks(var_BinID,var__)),var_Candidates=var_AllTrucks,var_Retries=cycled;var_Candidates=var_Candidates0,var_Retries=normal),remove_busy(var_Candidates,var_IdleCandidates),(var_IdleCandidates=[]->cc_log_status(var_BinID,deferred_busy,'Control center | deferred: all trucks busy for bin=~w, dispatching with fallback pool~n',[var_BinID]),clause(agent(var_CC),var__),cc_send(logger,inform(deferred_busy(var_BinID),var_CC));true),(var_IdleCandidates=[]->var_PickPool=var_Candidates;var_PickPool=var_IdleCandidates),random_pick(var_PickPool,var_Truck),retractall(last_try(var_BinID,var__)),assert(last_try(var_BinID,var_Truck)),retractall(inflight(var_BinID)),assert(inflight(var_BinID)),start_inflight_timer(var_BinID),cc_log_status(var_BinID,dispatch(var_Truck,var_Retries),'Control center | dispatch: truck=~w, bin=~w, mode=~w~n',[var_Truck,var_BinID,var_Retries]),clause(agent(var_CC),var__),cc_send(logger,inform(requesting(var_Truck,var_BinID,var_Retries),var_CC)),cc_send_collect(var_Truck,var_BinID).

process_waiting_bins(dummy):-clause(awaiting(var_BinID),var__),\+clause(inflight(var_BinID),var__),\+clause(assigned_bin(var_BinID,var__),var__),clause(bin_ready_for_collection(var_BinID),var__),(clause(dispatch_countdown(var_BinID,var_D),var__),var_D>0->fail;true),retractall(dispatch_countdown(var_BinID,var__)),(clause(retry_countdown(var_BinID,var_N),var__),var_N>0->fail;true),retractall(retry_countdown(var_BinID,var__)),dispatch_request(var_BinID),fail.

process_waiting_bins(dummy).

process_full_events(dummy):-clause(past(inform(full(var_BinID),var__Meta,var_Sender),var_T,var_Sender),var__),\+clause(cc_seen(var_T,full(var_BinID)),var__),assert(cc_seen(var_T,full(var_BinID))),cc_log_in(var_Sender,inform(full(var_BinID))),(clause(awaiting(var_BinID),var__)->(clause(bin_ready_for_collection(var_BinID),var__)->true;assert(bin_ready_for_collection(var_BinID)));cc_log_status(var_BinID,full_alert,'Control center | alert: full received from ~w~n',[var_BinID]),assert(awaiting(var_BinID)),retractall(assigned_bin(var_BinID,var__)),retractall(tried_trucks(var_BinID,var__)),assert(tried_trucks(var_BinID,[])),retractall(inflight(var_BinID)),retractall(bin_ready_for_collection(var_BinID)),assert(bin_ready_for_collection(var_BinID)),clear_timeout_count(var_BinID),clause(agent(var_CC),var__),cc_send(logger,inform(full_received(var_BinID),var_CC)),schedule_dispatch_delay(var_BinID)),fail.

process_full_events(dummy):-clause(past(inform(full(var_BinID),var_Sender),var_T,var_Sender),var__),\+clause(cc_seen(var_T,full(var_BinID)),var__),assert(cc_seen(var_T,full(var_BinID))),cc_log_in(var_Sender,inform(full(var_BinID))),(clause(awaiting(var_BinID),var__)->(clause(bin_ready_for_collection(var_BinID),var__)->true;assert(bin_ready_for_collection(var_BinID)));cc_log_status(var_BinID,full_alert,'Control center | alert: full received from ~w~n',[var_BinID]),assert(awaiting(var_BinID)),retractall(assigned_bin(var_BinID,var__)),retractall(tried_trucks(var_BinID,var__)),assert(tried_trucks(var_BinID,[])),retractall(bin_ready_for_collection(var_BinID)),assert(bin_ready_for_collection(var_BinID)),clear_timeout_count(var_BinID),clause(agent(var_CC),var__),cc_send(logger,inform(full_received(var_BinID),var_CC)),schedule_dispatch_delay(var_BinID)),fail.

process_full_events(dummy).

process_truck_events(dummy):-clause(past(inform(agree(var_Truck,var_BinID),var__Meta,var_Truck),var_T,var_Truck),var__),\+clause(cc_seen(var_T,agree(var_Truck,var_BinID)),var__),assert(cc_seen(var_T,agree(var_Truck,var_BinID))),cc_log_in(var_Truck,inform(agree(var_Truck,var_BinID))),cc_log_status(var_BinID,assigned(var_Truck),'Control center | assigned: truck=~w, bin=~w~n',[var_Truck,var_BinID]),retractall(assigned_bin(var_BinID,var__)),assert(assigned_bin(var_BinID,var_Truck)),retractall(tried_trucks(var_BinID,var__)),retractall(inflight(var_BinID)),clear_inflight_timer(var_BinID),retractall(retry_countdown(var_BinID,var__)),clear_timeout_count(var_BinID),clause(agent(var_CC),var__),cc_send(logger,inform(assigned(var_Truck,var_BinID),var_CC)),fail.

process_truck_events(dummy):-clause(past(inform(agree(var_Truck,var_BinID),var_Truck),var_T,var_Truck),var__),\+clause(cc_seen(var_T,agree(var_Truck,var_BinID)),var__),assert(cc_seen(var_T,agree(var_Truck,var_BinID))),cc_log_in(var_Truck,inform(agree(var_Truck,var_BinID))),cc_log_status(var_BinID,assigned(var_Truck),'Control center | assigned: truck=~w, bin=~w~n',[var_Truck,var_BinID]),retractall(assigned_bin(var_BinID,var__)),assert(assigned_bin(var_BinID,var_Truck)),retractall(tried_trucks(var_BinID,var__)),retractall(inflight(var_BinID)),clear_inflight_timer(var_BinID),retractall(retry_countdown(var_BinID,var__)),clear_timeout_count(var_BinID),clause(agent(var_CC),var__),cc_send(logger,inform(assigned(var_Truck,var_BinID),var_CC)),fail.

process_truck_events(dummy):-clause(past(inform(refuse(var_Truck,var_BinID),var__Meta,var_Truck),var_T,var_Truck),var__),\+clause(cc_seen(var_T,refuse(var_Truck,var_BinID)),var__),assert(cc_seen(var_T,refuse(var_Truck,var_BinID))),cc_log_in(var_Truck,inform(refuse(var_Truck,var_BinID))),cc_log_status(var_BinID,refused(var_Truck),'Control center | retry: truck=~w refused, bin=~w~n',[var_Truck,var_BinID]),(clause(tried_trucks(var_BinID,var_Tried),var__)->true;var_Tried=[]),retractall(tried_trucks(var_BinID,var__)),assert(tried_trucks(var_BinID,[var_Truck|var_Tried])),retractall(inflight(var_BinID)),clear_inflight_timer(var_BinID),schedule_retry(var_BinID,refused),clause(agent(var_CC),var__),cc_send(logger,inform(refused(var_Truck,var_BinID),var_CC)),cc_log_status(var_BinID,waiting_retry,'Control center | waiting: bin=~w queued after refusal~n',[var_BinID]),fail.

process_truck_events(dummy):-clause(past(inform(refuse(var_Truck,var_BinID),var_Truck),var_T,var_Truck),var__),\+clause(cc_seen(var_T,refuse(var_Truck,var_BinID)),var__),assert(cc_seen(var_T,refuse(var_Truck,var_BinID))),cc_log_in(var_Truck,inform(refuse(var_Truck,var_BinID))),cc_log_status(var_BinID,refused(var_Truck),'Control center | retry: truck=~w refused, bin=~w~n',[var_Truck,var_BinID]),(clause(tried_trucks(var_BinID,var_Tried),var__)->true;var_Tried=[]),retractall(tried_trucks(var_BinID,var__)),assert(tried_trucks(var_BinID,[var_Truck|var_Tried])),retractall(inflight(var_BinID)),clear_inflight_timer(var_BinID),schedule_retry(var_BinID,refused),clause(agent(var_CC),var__),cc_send(logger,inform(refused(var_Truck,var_BinID),var_CC)),cc_log_status(var_BinID,waiting_retry,'Control center | waiting: bin=~w queued after refusal~n',[var_BinID]),fail.

process_truck_events(dummy):-clause(past(inform(collected(var_Truck,var_BinID),var__Meta,var_Truck),var_T,var_Truck),var__),\+clause(cc_seen(var_T,collected(var_Truck,var_BinID)),var__),assert(cc_seen(var_T,collected(var_Truck,var_BinID))),cc_log_in(var_Truck,inform(collected(var_Truck,var_BinID))),cc_log_status(var_BinID,done(var_Truck),'Control center | done: truck=~w collected bin=~w, clear sent~n',[var_Truck,var_BinID]),retractall(assigned_bin(var_BinID,var__)),retractall(tried_trucks(var_BinID,var__)),clause(agent(var_CC),var__),cc_send(logger,inform(completed(var_Truck,var_BinID),var_CC)),cc_send_cleared(var_BinID),retractall(awaiting(var_BinID)),retractall(inflight(var_BinID)),clear_inflight_timer(var_BinID),retractall(bin_ready_for_collection(var_BinID)),retractall(retry_countdown(var_BinID,var__)),clear_timeout_count(var_BinID),fail.

process_truck_events(dummy):-clause(past(inform(collected(var_Truck,var_BinID),var_Truck),var_T,var_Truck),var__),\+clause(cc_seen(var_T,collected(var_Truck,var_BinID)),var__),assert(cc_seen(var_T,collected(var_Truck,var_BinID))),cc_log_in(var_Truck,inform(collected(var_Truck,var_BinID))),cc_log_status(var_BinID,done(var_Truck),'Control center | done: truck=~w collected bin=~w, clear sent~n',[var_Truck,var_BinID]),retractall(assigned_bin(var_BinID,var__)),retractall(tried_trucks(var_BinID,var__)),clause(agent(var_CC),var__),cc_send(logger,inform(completed(var_Truck,var_BinID),var_CC)),cc_send_cleared(var_BinID),retractall(awaiting(var_BinID)),retractall(inflight(var_BinID)),clear_inflight_timer(var_BinID),retractall(bin_ready_for_collection(var_BinID)),retractall(retry_countdown(var_BinID,var__)),clear_timeout_count(var_BinID),fail.

process_truck_events(dummy).

evi(monitor(dummy)):-tick_retry_queue(dummy),tick_dispatch_queue(dummy),tick_inflight_watchdog(dummy),process_full_events(dummy),process_truck_events(dummy),process_waiting_bins(dummy).

monitor(dummy).

:-dynamic receive/1.

:-dynamic send/2.

:-dynamic isa/3.

safe_told(var_Ag,var_M):-current_predicate(told/2)->told(var_Ag,var_M);true.

safe_told(var_Ag,var_M,var_T):-current_predicate(told/3)->told(var_Ag,var_M,var_T);var_T=0.

safe_tell(var_To,var_Ag,var_M):-current_predicate(tell/3)->tell(var_To,var_Ag,var_M);true.

receive(send_message(var_X,var_Ag)):-safe_told(var_Ag,send_message(var_X)),call_send_message(var_X,var_Ag).

receive(propose(var_A,var_C,var_Ag)):-safe_told(var_Ag,propose(var_A,var_C)),call_propose(var_A,var_C,var_Ag).

receive(cfp(var_A,var_C,var_Ag)):-safe_told(var_Ag,cfp(var_A,var_C)),call_cfp(var_A,var_C,var_Ag).

receive(accept_proposal(var_A,var_Mp,var_Ag)):-safe_told(var_Ag,accept_proposal(var_A,var_Mp),var_T),call_accept_proposal(var_A,var_Mp,var_Ag,var_T).

receive(reject_proposal(var_A,var_Mp,var_Ag)):-safe_told(var_Ag,reject_proposal(var_A,var_Mp),var_T),call_reject_proposal(var_A,var_Mp,var_Ag,var_T).

receive(failure(var_A,var_M,var_Ag)):-safe_told(var_Ag,failure(var_A,var_M),var_T),call_failure(var_A,var_M,var_Ag,var_T).

receive(cancel(var_A,var_Ag)):-safe_told(var_Ag,cancel(var_A)),call_cancel(var_A,var_Ag).

receive(execute_proc(var_X,var_Ag)):-safe_told(var_Ag,execute_proc(var_X)),call_execute_proc(var_X,var_Ag).

receive(query_ref(var_X,var_N,var_Ag)):-safe_told(var_Ag,query_ref(var_X,var_N)),call_query_ref(var_X,var_N,var_Ag).

receive(inform(var_X,var_M,var_Ag)):-safe_told(var_Ag,inform(var_X,var_M),var_T),call_inform(var_X,var_Ag,var_M,var_T).

receive(inform(var_X,var_Ag)):-safe_told(var_Ag,inform(var_X),var_T),call_inform(var_X,var_Ag,var_T).

receive(refuse(var_X,var_Ag)):-safe_told(var_Ag,refuse(var_X),var_T),call_refuse(var_X,var_Ag,var_T).

receive(agree(var_X,var_Ag)):-safe_told(var_Ag,agree(var_X)),call_agree(var_X,var_Ag).

receive(confirm(var_X,var_Ag)):-safe_told(var_Ag,confirm(var_X),var_T),call_confirm(var_X,var_Ag,var_T).

receive(disconfirm(var_X,var_Ag)):-safe_told(var_Ag,disconfirm(var_X)),call_disconfirm(var_X,var_Ag).

receive(reply(var_X,var_Ag)):-safe_told(var_Ag,reply(var_X)).

send(var_To,query_ref(var_X,var_N,var_Ag)):-safe_tell(var_To,var_Ag,query_ref(var_X,var_N)),send_m(var_To,query_ref(var_X,var_N,var_Ag)).

send(var_To,send_message(var_X,var_Ag)):-safe_tell(var_To,var_Ag,send_message(var_X)),send_m(var_To,send_message(var_X,var_Ag)).

send(var_To,reject_proposal(var_X,var_L,var_Ag)):-safe_tell(var_To,var_Ag,reject_proposal(var_X,var_L)),send_m(var_To,reject_proposal(var_X,var_L,var_Ag)).

send(var_To,accept_proposal(var_X,var_L,var_Ag)):-safe_tell(var_To,var_Ag,accept_proposal(var_X,var_L)),send_m(var_To,accept_proposal(var_X,var_L,var_Ag)).

send(var_To,confirm(var_X,var_Ag)):-safe_tell(var_To,var_Ag,confirm(var_X)),send_m(var_To,confirm(var_X,var_Ag)).

send(var_To,propose(var_X,var_C,var_Ag)):-safe_tell(var_To,var_Ag,propose(var_X,var_C)),send_m(var_To,propose(var_X,var_C,var_Ag)).

send(var_To,disconfirm(var_X,var_Ag)):-safe_tell(var_To,var_Ag,disconfirm(var_X)),send_m(var_To,disconfirm(var_X,var_Ag)).

send(var_To,inform(var_X,var_M,var_Ag)):-safe_tell(var_To,var_Ag,inform(var_X,var_M)),send_m(var_To,inform(var_X,var_M,var_Ag)).

send(var_To,inform(var_X,var_Ag)):-safe_tell(var_To,var_Ag,inform(var_X)),send_m(var_To,inform(var_X,var_Ag)).

send(var_To,refuse(var_X,var_Ag)):-safe_tell(var_To,var_Ag,refuse(var_X)),send_m(var_To,refuse(var_X,var_Ag)).

send(var_To,failure(var_X,var_M,var_Ag)):-safe_tell(var_To,var_Ag,failure(var_X,var_M)),send_m(var_To,failure(var_X,var_M,var_Ag)).

send(var_To,execute_proc(var_X,var_Ag)):-safe_tell(var_To,var_Ag,execute_proc(var_X)),send_m(var_To,execute_proc(var_X,var_Ag)).

send(var_To,agree(var_X,var_Ag)):-safe_tell(var_To,var_Ag,agree(var_X)),send_m(var_To,agree(var_X,var_Ag)).

call_send_message(var_X,var_Ag):-send_message(var_X,var_Ag).

call_execute_proc(var_X,var_Ag):-execute_proc(var_X,var_Ag).

call_query_ref(var_X,var_N,var_Ag):-clause(agent(var_A),var__),not(var(var_X)),meta_ref(var_X,var_N,var_L,var_Ag),a(message(var_Ag,inform(query_ref(var_X,var_N),values(var_L),var_A))).

call_query_ref(var_X,var__,var_Ag):-clause(agent(var_A),var__),var(var_X),a(message(var_Ag,refuse(query_ref(variable),motivation(refused_variables),var_A))).

call_query_ref(var_X,var_N,var_Ag):-clause(agent(var_A),var__),not(var(var_X)),not(meta_ref(var_X,var_N,var__,var__)),a(message(var_Ag,inform(query_ref(var_X,var_N),motivation(no_values),var_A))).

call_agree(var_X,var_Ag):-clause(agent(var_A),var__),ground(var_X),meta_agree(var_X,var_Ag),a(message(var_Ag,inform(agree(var_X),values(yes),var_A))).

call_confirm(var_X,var_Ag,var_T):-ground(var_X),statistics(walltime,[var_Tp,var__]),asse_cosa(past_event(var_X,var_T)),retractall(past(var_X,var_Tp,var_Ag)),assert(past(var_X,var_Tp,var_Ag)).

call_disconfirm(var_X,var_Ag):-ground(var_X),retractall(past(var_X,var__,var_Ag)),retractall(past_event(var_X,var__)).

call_agree(var_X,var_Ag):-clause(agent(var_A),var__),ground(var_X),not(meta_agree(var_X,var__)),a(message(var_Ag,inform(agree(var_X),values(no),var_A))).

call_agree(var_X,var_Ag):-clause(agent(var_A),var__),not(ground(var_X)),a(message(var_Ag,refuse(agree(variable),motivation(refused_variables),var_A))).

call_inform(var_X,var_Ag,var_M,var_T):-asse_cosa(past_event(inform(var_X,var_M,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(inform(var_X,var_M,var_Ag),var__,var_Ag)),assert(past(inform(var_X,var_M,var_Ag),var_Tp,var_Ag)),trigger_inform_handlers(var_X,var_M,var_Ag).

call_inform(var_X,var_Ag,var_T):-asse_cosa(past_event(inform(var_X,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(inform(var_X,var_Ag),var__,var_Ag)),assert(past(inform(var_X,var_Ag),var_Tp,var_Ag)),trigger_inform_handlers(var_X,none,var_Ag).

trigger_inform_handlers(var_X,var_M,var_Ag):-catch(call(eve(inform_E(var_X,var_Ag))),_690135,true),catch(call(eve(inform_E(var_X,var_M,var_Ag))),_690163,true),catch(call(eve(inform_E(var_X))),_690187,true).

call_refuse(var_X,var_Ag,var_T):-clause(agent(var_A),var__),asse_cosa(past_event(var_X,var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(var_X,var__,var_Ag)),assert(past(var_X,var_Tp,var_Ag)),a(message(var_Ag,reply(received(var_X),var_A))).

call_cfp(var_A,var_C,var_Ag):-clause(agent(var_AgI),var__),clause(ext_agent(var_Ag,_689899,var_Ontology,_689903),_689893),asserisci_ontologia(var_Ag,var_Ontology,var_A),once(call_meta_execute_cfp(var_A,var_C,var_Ag,_689937)),a(message(var_Ag,propose(var_A,[_689937],var_AgI))),retractall(ext_agent(var_Ag,_689975,var_Ontology,_689979)).

call_propose(var_A,var_C,var_Ag):-clause(agent(var_AgI),var__),clause(ext_agent(var_Ag,_689773,var_Ontology,_689777),_689767),asserisci_ontologia(var_Ag,var_Ontology,var_A),once(call_meta_execute_propose(var_A,var_C,var_Ag)),a(message(var_Ag,accept_proposal(var_A,[],var_AgI))),retractall(ext_agent(var_Ag,_689843,var_Ontology,_689847)).

call_propose(var_A,var_C,var_Ag):-clause(agent(var_AgI),var__),clause(ext_agent(var_Ag,_689661,var_Ontology,_689665),_689655),not(call_meta_execute_propose(var_A,var_C,var_Ag)),a(message(var_Ag,reject_proposal(var_A,[],var_AgI))),retractall(ext_agent(var_Ag,_689717,var_Ontology,_689721)).

call_accept_proposal(var_A,var_Mp,var_Ag,var_T):-asse_cosa(past_event(accepted_proposal(var_A,var_Mp,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(accepted_proposal(var_A,var_Mp,var_Ag),var__,var_Ag)),assert(past(accepted_proposal(var_A,var_Mp,var_Ag),var_Tp,var_Ag)).

call_reject_proposal(var_A,var_Mp,var_Ag,var_T):-asse_cosa(past_event(rejected_proposal(var_A,var_Mp,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(rejected_proposal(var_A,var_Mp,var_Ag),var__,var_Ag)),assert(past(rejected_proposal(var_A,var_Mp,var_Ag),var_Tp,var_Ag)).

call_failure(var_A,var_M,var_Ag,var_T):-asse_cosa(past_event(failed_action(var_A,var_M,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(failed_action(var_A,var_M,var_Ag),var__,var_Ag)),assert(past(failed_action(var_A,var_M,var_Ag),var_Tp,var_Ag)).

call_cancel(var_A,var_Ag):-if(clause(high_action(var_A,var_Te,var_Ag),_689225),retractall(high_action(var_A,var_Te,var_Ag)),true),if(clause(normal_action(var_A,var_Te,var_Ag),_689259),retractall(normal_action(var_A,var_Te,var_Ag)),true).

external_refused_action_propose(var_A,var_Ag):-clause(not_executable_action_propose(var_A,var_Ag),var__).

evi(external_refused_action_propose(var_A,var_Ag)):-clause(agent(var_Ai),var__),a(message(var_Ag,failure(var_A,motivation(false_conditions),var_Ai))),retractall(not_executable_action_propose(var_A,var_Ag)).

refused_message(var_AgM,var_Con):-clause(eliminated_message(var_AgM,var__,var__,var_Con,var__),var__).

refused_message(var_To,var_M):-clause(eliminated_message(var_M,var_To,motivation(conditions_not_verified)),_689041).

evi(refused_message(var_AgM,var_Con)):-clause(agent(var_Ai),var__),a(message(var_AgM,inform(var_Con,motivation(refused_message),var_Ai))),retractall(eliminated_message(var_AgM,var__,var__,var_Con,var__)),retractall(eliminated_message(var_Con,var_AgM,motivation(conditions_not_verified))).

send_jasper_return_message(var_X,var_S,var_T,var_S0):-clause(agent(var_Ag),_688889),a(message(var_S,send_message(sent_rmi(var_X,var_T,var_S0),var_Ag))).

gest_learn(var_H):-clause(past(learn(var_H),var_T,var_U),_688837),learn_if(var_H,var_T,var_U).

evi(gest_learn(var_H)):-retractall(past(learn(var_H),_688713,_688715)),clause(agente(_688735,_688737,_688739,var_S),_688731),name(var_S,var_N),append(var_L,[46,112,108],var_N),name(var_F,var_L),manage_lg(var_H,var_F),a(learned(var_H)).

cllearn:-clause(agente(_688507,_688509,_688511,var_S),_688503),name(var_S,var_N),append(var_L,[46,112,108],var_N),append(var_L,[46,116,120,116],var_To),name(var_FI,var_To),open(var_FI,read,_688607,[]),repeat,read(_688607,var_T),arg(1,var_T,var_H),write(var_H),nl,var_T==end_of_file,!,close(_688607).

send_msg_learn(var_T,var_A,var_Ag):-a(message(var_Ag,confirm(learn(var_T),var_A))).
