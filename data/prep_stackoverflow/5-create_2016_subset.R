source('connect_postgres.R')

subQuestions <- dbGetQuery(con, "select * from questions where creationdate like '2016%'")

write.csv(subQuestions, file = 'questions-2016.csv', row.names = FALSE)

subAnswers <- dbGetQuery(con, "select * from answers where creationdate like '2016%'")

write.csv(subAnswers, file = 'answers-2016.csv', row.names = FALSE)

subQuestionsTags <- dbGetQuery(con, "select questions.questionid,tag from questions join questions_tags on questions.questionid = questions_tags.questionid where creationdate like '2016%'")

write.csv(subQuestionsTags, file = 'questions_tags-2016.csv', row.names = FALSE)

subUsers <- dbGetQuery(con, "select * from users where userid in (
    select distinct ownerid from questions
       where creationdate like '2016%'
    union
    select distinct ownerid from answers
       where creationdate like '2016%')")
     
write.csv(subUsers, file = 'users-2016.csv', row.names = FALSE)
