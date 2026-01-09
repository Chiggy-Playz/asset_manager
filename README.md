# Asset Manager

## Database stuff

Schema can be found in db/schema.sql
To initialize the database, run:

```bash
$Env:DATABASE_URL="connection_string"
dbmate up
```

Replace `connection_string` with your actual database connection string, from the supabase dashboard.