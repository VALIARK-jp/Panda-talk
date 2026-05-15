begin;

alter table public.panda_questions
  add constraint panda_questions_text_max_length
  check (char_length(text) <= 100)
  not valid;

commit;
