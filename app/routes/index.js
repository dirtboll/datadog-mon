var express = require('express');
var router = express.Router();
const { Postgres } = require('../libs/database');

/* GET home page. */
router.get('/', async function(req, res, next) {
  const todos = await Postgres.client.todos.findMany()
  res.render('index', { 
    title: 'TODO App',
    todos
  });
});
router.post('/', async function(req, res, next) {
  if (!!req.body.todo)
    await Postgres.client.todos.create({data: {
      content: req.body.todo
    }})
  res.redirect('/')
})
router.post('/delete', async function(req, res, next) {
  if (!!req.body.todo)
    await Postgres.client.todos.delete({
      where: {
        id: parseInt(req.body.todo)
      }
    })
  res.redirect('/')
})

module.exports = router;
