const { PrismaClient } = require("@prisma/client")

class Postgres {
  static #client
  /**
   * Returns the sum of a and b
   * @returns {PrismaClient}
   */
  static get client() {
    if (!Postgres.#client) {
      Postgres.#client = new PrismaClient()
    }
    return Postgres.#client
  }
}

module.exports = { Postgres }