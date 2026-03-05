
evi(heartbeat(dummy)):-clause(agent(var_TruckID),var__),tick_busy(dummy),availability_state(var_State),(heartbeat_log_needed(var_State)->format('Truck ~w | state: ~w~n',[var_TruckID,var_State]);true).

heartbeat(dummy).

heartbeat_log_needed(var_State):-clause(last_heartbeat_state(var_State),var__)->fail;retractall(last_heartbeat_state(var__)),assert(last_heartbeat_state(var_State)),true.

availability_state(available):- \+clause(busy_cycles(var_N),var__),!.

availability_state(available):-clause(busy_cycles(var_N),var__),var_N=<0,!.

availability_state(busy):-clause(busy_cycles(var_N),var__),var_N>0.

collection_duration_cycles(8).

decision_delay_cycles(1).

collection_start_delay_cycles(1).

refuse_busy_cycles(2).

accept_probability_percent(90).

tick_busy(dummy):-clause(busy_cycles(var_N),var__),var_N>0,var_N1 is var_N-1,retractall(busy_cycles(var__)),assert(busy_cycles(var_N1)),!.

tick_busy(dummy).

truck_available(dummy):-availability_state(available),accept_probability_percent(var_P),random(0,100,var_R),var_R<var_P.

schedule_decision(var_T,var_BinID):-decision_delay_cycles(var_Cycles),retractall(decision_countdown(var_T,var_BinID,var__)),assert(decision_countdown(var_T,var_BinID,var_Cycles)).

tick_decision_queue(dummy):-clause(decision_countdown(var_T,var_BinID,var_N),var__),var_N>0,var_N1 is var_N-1,retractall(decision_countdown(var_T,var_BinID,var__)),assert(decision_countdown(var_T,var_BinID,var_N1)),fail.

tick_decision_queue(dummy).

tick_collection_start(dummy):-clause(collection_start_countdown(var_BinID,var_N),var__),var_N>0,var_N1 is var_N-1,retractall(collection_start_countdown(var_BinID,var__)),assert(collection_start_countdown(var_BinID,var_N1)),fail.

tick_collection_start(dummy).

ensure_busy_at_least(var_Cycles):-clause(busy_cycles(var_N),var__),var_N>=var_Cycles->true;retractall(busy_cycles(var__)),assert(busy_cycles(var_Cycles)).

normalize_collect_msg(inform(collect(var_BinID),var__Meta,var__From),var_BinID).

normalize_collect_msg(inform(collect(var_BinID),var__From),var_BinID).

normalize_collect_msg(inform(collect(var_BinID)),var_BinID).

normalize_collect_msg(collect(var_BinID),var_BinID).

normalize_collect_msg(inform(collect(var_BinID),var__,var__,var__),var_BinID).

process_collect_orders(dummy):-clause(past(var_Msg,var_T,var__Sender),var__),normalize_collect_msg(var_Msg,var_BinID),\+clause(order_seen(var_T,var_BinID),var__),assert(order_seen(var_T,var_BinID)),clause(agent(var_TruckID),var__),format('Truck ~w | request: collect ~w~n',[var_TruckID,var_BinID]),schedule_decision(var_T,var_BinID),fail.

process_collect_orders(dummy).

process_pending_decisions(dummy):-clause(decision_countdown(var_T,var_BinID,0),var__),clause(agent(var_TruckID),var__),(truck_available(dummy)->format('Truck ~w | decision: accept ~w~n',[var_TruckID,var_BinID]),retractall(busy_cycles(var__)),collection_start_delay_cycles(var_StartDelay),collection_duration_cycles(var_ServiceCycles),var_TotalCycles is var_StartDelay+var_ServiceCycles,assert(busy_cycles(var_TotalCycles)),retractall(active_collection(var__)),assert(active_collection(var_BinID)),retractall(collection_started(var__)),retractall(collection_start_countdown(var_BinID,var__)),assert(collection_start_countdown(var_BinID,var_StartDelay)),a(message(logger,inform(accepted(var_TruckID,var_BinID),var_TruckID))),a(message(control_center,inform(agree(var_TruckID,var_BinID),var_TruckID)));format('Truck ~w | decision: refuse ~w~n',[var_TruckID,var_BinID]),refuse_busy_cycles(var_RefCycles),ensure_busy_at_least(var_RefCycles),a(message(logger,inform(refused(var_TruckID,var_BinID),var_TruckID))),a(message(control_center,inform(refuse(var_TruckID,var_BinID),var_TruckID)))),retractall(decision_countdown(var_T,var_BinID,var__)),fail.

process_pending_decisions(dummy).

evi(start_collection(dummy)):-clause(active_collection(var_BinID),var__),clause(collection_start_countdown(var_BinID,0),var__),\+clause(collection_started(var_BinID),var__),clause(agent(var_TruckID),var__),assert(collection_started(var_BinID)),a(message(logger,inform(working(var_TruckID,var_BinID),var_TruckID))).

start_collection(dummy).

evi(complete_collection(dummy)):-clause(active_collection(var_BinID),var__),clause(collection_started(var_BinID),var__),availability_state(available),clause(agent(var_TruckID),var__),retractall(active_collection(var__)),retractall(collection_started(var__)),retractall(collection_start_countdown(var_BinID,var__)),a(message(control_center,inform(collected(var_TruckID,var_BinID),var_TruckID))),a(message(logger,inform(ready(var_TruckID),var_TruckID))).

complete_collection(dummy).

evi(order_monitor(dummy)):-tick_decision_queue(dummy),tick_collection_start(dummy),process_collect_orders(dummy),process_pending_decisions(dummy).

order_monitor(dummy).

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

trigger_inform_handlers(var_X,var_M,var_Ag):-catch(call(eve(inform_E(var_X,var_Ag))),_570271,true),catch(call(eve(inform_E(var_X,var_M,var_Ag))),_570299,true),catch(call(eve(inform_E(var_X))),_570323,true).

call_refuse(var_X,var_Ag,var_T):-clause(agent(var_A),var__),asse_cosa(past_event(var_X,var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(var_X,var__,var_Ag)),assert(past(var_X,var_Tp,var_Ag)),a(message(var_Ag,reply(received(var_X),var_A))).

call_cfp(var_A,var_C,var_Ag):-clause(agent(var_AgI),var__),clause(ext_agent(var_Ag,_570035,var_Ontology,_570039),_570029),asserisci_ontologia(var_Ag,var_Ontology,var_A),once(call_meta_execute_cfp(var_A,var_C,var_Ag,_570073)),a(message(var_Ag,propose(var_A,[_570073],var_AgI))),retractall(ext_agent(var_Ag,_570111,var_Ontology,_570115)).

call_propose(var_A,var_C,var_Ag):-clause(agent(var_AgI),var__),clause(ext_agent(var_Ag,_569909,var_Ontology,_569913),_569903),asserisci_ontologia(var_Ag,var_Ontology,var_A),once(call_meta_execute_propose(var_A,var_C,var_Ag)),a(message(var_Ag,accept_proposal(var_A,[],var_AgI))),retractall(ext_agent(var_Ag,_569979,var_Ontology,_569983)).

call_propose(var_A,var_C,var_Ag):-clause(agent(var_AgI),var__),clause(ext_agent(var_Ag,_569797,var_Ontology,_569801),_569791),not(call_meta_execute_propose(var_A,var_C,var_Ag)),a(message(var_Ag,reject_proposal(var_A,[],var_AgI))),retractall(ext_agent(var_Ag,_569853,var_Ontology,_569857)).

call_accept_proposal(var_A,var_Mp,var_Ag,var_T):-asse_cosa(past_event(accepted_proposal(var_A,var_Mp,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(accepted_proposal(var_A,var_Mp,var_Ag),var__,var_Ag)),assert(past(accepted_proposal(var_A,var_Mp,var_Ag),var_Tp,var_Ag)).

call_reject_proposal(var_A,var_Mp,var_Ag,var_T):-asse_cosa(past_event(rejected_proposal(var_A,var_Mp,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(rejected_proposal(var_A,var_Mp,var_Ag),var__,var_Ag)),assert(past(rejected_proposal(var_A,var_Mp,var_Ag),var_Tp,var_Ag)).

call_failure(var_A,var_M,var_Ag,var_T):-asse_cosa(past_event(failed_action(var_A,var_M,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(failed_action(var_A,var_M,var_Ag),var__,var_Ag)),assert(past(failed_action(var_A,var_M,var_Ag),var_Tp,var_Ag)).

call_cancel(var_A,var_Ag):-if(clause(high_action(var_A,var_Te,var_Ag),_569361),retractall(high_action(var_A,var_Te,var_Ag)),true),if(clause(normal_action(var_A,var_Te,var_Ag),_569395),retractall(normal_action(var_A,var_Te,var_Ag)),true).

external_refused_action_propose(var_A,var_Ag):-clause(not_executable_action_propose(var_A,var_Ag),var__).

evi(external_refused_action_propose(var_A,var_Ag)):-clause(agent(var_Ai),var__),a(message(var_Ag,failure(var_A,motivation(false_conditions),var_Ai))),retractall(not_executable_action_propose(var_A,var_Ag)).

refused_message(var_AgM,var_Con):-clause(eliminated_message(var_AgM,var__,var__,var_Con,var__),var__).

refused_message(var_To,var_M):-clause(eliminated_message(var_M,var_To,motivation(conditions_not_verified)),_569177).

evi(refused_message(var_AgM,var_Con)):-clause(agent(var_Ai),var__),a(message(var_AgM,inform(var_Con,motivation(refused_message),var_Ai))),retractall(eliminated_message(var_AgM,var__,var__,var_Con,var__)),retractall(eliminated_message(var_Con,var_AgM,motivation(conditions_not_verified))).

send_jasper_return_message(var_X,var_S,var_T,var_S0):-clause(agent(var_Ag),_569025),a(message(var_S,send_message(sent_rmi(var_X,var_T,var_S0),var_Ag))).

gest_learn(var_H):-clause(past(learn(var_H),var_T,var_U),_568973),learn_if(var_H,var_T,var_U).

evi(gest_learn(var_H)):-retractall(past(learn(var_H),_568849,_568851)),clause(agente(_568871,_568873,_568875,var_S),_568867),name(var_S,var_N),append(var_L,[46,112,108],var_N),name(var_F,var_L),manage_lg(var_H,var_F),a(learned(var_H)).

cllearn:-clause(agente(_568643,_568645,_568647,var_S),_568639),name(var_S,var_N),append(var_L,[46,112,108],var_N),append(var_L,[46,116,120,116],var_To),name(var_FI,var_To),open(var_FI,read,_568743,[]),repeat,read(_568743,var_T),arg(1,var_T,var_H),write(var_H),nl,var_T==end_of_file,!,close(_568743).

send_msg_learn(var_T,var_A,var_Ag):-a(message(var_Ag,confirm(learn(var_T),var_A))).
