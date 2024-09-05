-- CreateTable
CREATE TABLE "Todos" (
    "id" SERIAL NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "content" TEXT,

    CONSTRAINT "Todos_pkey" PRIMARY KEY ("id")
);
