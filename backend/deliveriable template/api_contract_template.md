\#Users

\* User object

```

{

&#x20; id: integer

&#x20; username: string

&#x20; email: string

&#x20; created\_at: datetime(iso 8601)

&#x20; updated\_at: datetime(iso 8601)

}

```

\*\*GET /users\*\*

\----

&#x20; Returns all users in the system.

\* \*\*URL Params\*\*  

&#x20; None

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

\* \*\*Success Response:\*\*  

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  

```

{

&#x20; users: \[

&#x20;          {<user\_object>},

&#x20;          {<user\_object>},

&#x20;          {<user\_object>}

&#x20;        ]

}

```



\*\*GET /users/:id\*\*

\----

&#x20; Returns the specified user.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\* 

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  `{ <user\_object> }` 

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "User doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\*\*GET /users/:id/orders\*\*

\----

&#x20; Returns all Orders associated with the specified user.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\*  

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  

```

{

&#x20; orders: \[

&#x20;          {<order\_object>},

&#x20;          {<order\_object>},

&#x20;          {<order\_object>}

&#x20;        ]

}

```

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "User doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\*\*POST /users\*\*

\----

&#x20; Creates a new User and returns the new object.

\* \*\*URL Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

\* \*\*Data Params\*\*  

```

&#x20; {

&#x20;   username: string,

&#x20;   email: string

&#x20; }

```

\* \*\*Success Response:\*\*  

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  `{ <user\_object> }` 



\*\*PATCH /users/:id\*\*

\----

&#x20; Updates fields on the specified user and returns the updated object.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

```

&#x20; {

&#x20; 	username: string,

&#x20;   email: string

&#x20; }

```

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\* 

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  `{ <user\_object> }`  

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "User doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\*\*DELETE /users/:id\*\*

\----

&#x20; Deletes the specified user.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\* 

&#x20; \* \*\*Code:\*\* 204 

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "User doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\#Products

\* Product object

```

{

&#x20; id: integer

&#x20; name: string

&#x20; cost: float(2)

&#x20; available\_quantity: integer

&#x20; created\_at: datetime(iso 8601)

&#x20; updated\_at: datetime(iso 8601)

}

```

\*\*GET /products\*\*

\----

&#x20; Returns all products in the system.

\* \*\*URL Params\*\*  

&#x20; None

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

\* \*\*Success Response:\*\* 

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  

```

{

&#x20; products: \[

&#x20;          {<product\_object>},

&#x20;          {<product\_object>},

&#x20;          {<product\_object>}

&#x20;        ]

}

``` 



\*\*GET /products/:id\*\*

\----

&#x20; Returns the specified product.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\*  

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  `{ <product\_object> }` 

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "Product doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\*\*GET /products/:id/orders\*\*

\----

&#x20; Returns all Orders associated with the specified product.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\* 

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  

```

{

&#x20; orders: \[

&#x20;          {<order\_object>},

&#x20;          {<order\_object>},

&#x20;          {<order\_object>}

&#x20;        ]

}

``` 

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "Product doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\*\*POST /products\*\*

\----

&#x20; Creates a new Product and returns the new object.

\* \*\*URL Params\*\*  

&#x20; None

\* \*\*Data Params\*\*  

```

&#x20; {

&#x20;   name: string

&#x20;   cost: float(2)

&#x20;   available\_quantity: integer

&#x20; }

```

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

\* \*\*Success Response:\*\*  

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  `{ <product\_object> }` 



\*\*PATCH /products/:id\*\*

\----

&#x20; Updates fields on the specified product and returns the updated object.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

```

&#x20; {

&#x20; 	name: string

&#x20;   cost: float(2)

&#x20;   available\_quantity: integer

&#x20; }

```

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\* 

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  `{ <product\_object> }`  

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "Product doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\*\*DELETE /products/:id\*\*

\----

&#x20; Deletes the specified product.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\*  

&#x20; \* \*\*Code:\*\* 204

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "Product doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\#Orders

\* Order object

```

{

&#x20; id: integer

&#x20; user\_id: <user\_id>

&#x20; total: float(2)

&#x20; products: \[

&#x20;             { 

&#x20;               product: <product\_id>,

&#x20;               quantity: integer 

&#x20;             },

&#x20;             { 

&#x20;               product: <product\_id>,

&#x20;               quantity: integer 

&#x20;             },

&#x20;             { 

&#x20;               product: <product\_id>,

&#x20;               quantity: integer 

&#x20;             },

&#x20;           ]

&#x20; created\_at: datetime(iso 8601)

&#x20; updated\_at: datetime(iso 8601)

}

```

\*\*GET /orders\*\*

\----

&#x20; Returns all users in the system.

\* \*\*URL Params\*\*  

&#x20; None

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

\* \*\*Success Response:\*\* 

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  

```

{

&#x20; orders: \[

&#x20;          {<order\_object>},

&#x20;          {<order\_object>},

&#x20;          {<order\_object>}

&#x20;        ]

}

``` 



\*\*GET /orders/:id\*\*

\----

&#x20; Returns the specified order.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\*  

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  `{ <order\_object> }` 

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "Order doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\*\*GET /orders/:id/products\*\*

\----

&#x20; Returns all Products associated with the specified order.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\*  

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  

```

{

&#x20; products: \[

&#x20;          {<product\_object>},

&#x20;          {<product\_object>},

&#x20;          {<product\_object>}

&#x20;        ]

}

```

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "Order doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\*\*GET /orders/:id/user\*\*

\----

&#x20; Returns all Users associated with the specified order.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\* `{ <user\_object> }`  

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "Order doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\*\*POST /orders\*\*

\----

&#x20; Creates a new Order and returns the new object.

\* \*\*URL Params\*\*  

&#x20; None

\* \*\*Data Params\*\*  

```

&#x20; {

&#x20; 	user\_id: <user\_id>

&#x20; 	product: <product\_id>,

&#x20; 	quantity: integer 

&#x20; }

```

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

\* \*\*Success Response:\*\*  

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  `{ <order\_object> }` 



\*\*PATCH /orders/:id\*\*

\----

&#x20; Updates fields on the specified order and returns the updated object.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

```

&#x20; {

&#x20; 	product: <product\_id>,

&#x20; 	quantity: integer 

&#x20; }

```

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\*  

\* \*\*Code:\*\* 200  

&#x20; \*\*Content:\*\*  `{ <order\_object> }` 

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "Order doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`



\*\*DELETE /orders/:id\*\*

\----

&#x20; Deletes the specified order.

\* \*\*URL Params\*\*  

&#x20; \*Required:\* `id=\[integer]`

\* \*\*Data Params\*\*  

&#x20; None

\* \*\*Headers\*\*  

&#x20; Content-Type: application/json  

&#x20; Authorization: Bearer `<OAuth Token>`

\* \*\*Success Response:\*\* 

&#x20; \* \*\*Code:\*\* 204 

\* \*\*Error Response:\*\*  

&#x20; \* \*\*Code:\*\* 404  

&#x20; \*\*Content:\*\* `{ error : "Order doesn't exist" }`  

&#x20; OR  

&#x20; \* \*\*Code:\*\* 401  

&#x20; \*\*Content:\*\* `{ error : error : "You are unauthorized to make this request." }`

