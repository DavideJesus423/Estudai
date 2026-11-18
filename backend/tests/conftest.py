import os

# Precisa vir antes de importar app.*: Settings lê estas variáveis na importação.
os.environ.setdefault("DATABASE_URL", "mysql+pymysql://u:p@127.0.0.1:3306/db")
os.environ.setdefault("JWT_SECRET", "x" * 48)
