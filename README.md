# My ActiveRecord

### Description

MyAR is a project I built to learn more about the Rails ORM, ActiveRecord.

Each file in lib/ corresponds to ActiveRecord functionality:

* sql_object is responsible for the ActiveRecord::Base logic
* searchable handles the packages SQL queries into bite-sized methods, such as ::where
* associatable handles the relationships between objects in different tables. Methods here include belongs_to, has_many and has_one_through
