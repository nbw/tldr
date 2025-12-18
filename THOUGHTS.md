For JSON there are a few operators:

key, index, map/collect, filter,

```
{
   "items": [{
      "id": 1
      "name": "Item 1"
      "description": {
         "title": "Item 1 Description",
         "content": "This is the description of Item 1."
      },
      "image": {
         "url": "https://example.com/image.jpg",
         "alt": "Item 1 Image"
      },
      "urls": [
         "https://example.com/item1",
         "https://example.com/item2"
      ]
   }]
}
```

["item"].collect

Steps: [key:"item", map, ]

step for INDEX
step for individual fields
step for formatting a single field (ex: id into url)

- make plan with steps

- make all actions work on lists
- maybe a convert to feed item action (whch is really just extract)


# AI

the ai will:

- generate a step by step plan
- must confirm each step of the plan piece by piece
- if an a step in the plan fails, don't change previous steps, instead just propose a new current step
- have the ability to test the plan (or a step)
- have the ability to GET a payload from a url
- have the ability to save a plan once confirmed
- have the ability to get a new UUID
