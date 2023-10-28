def bubble_sort(queue):
   #2. Do sorting according to weights
    n = len(queue)
    # Traverse through all array elements
    for i in range(n-1):
        # range(n) also work but outer loop will
        # repeat one time more than needed.
        # Last i elements are already in place
        for j in range(0, n-i-1):
            # traverse the array from 0 to n-i-1
            # Swap if the element found is greater
            # than the next element

            # Add condition, if they have the same wait, sort them in character number ordering
            if queue[j][3] < queue[j + 1][3]:
                queue[j], queue[j + 1] = queue[j + 1], queue[j]

    return queue

dummy_node_name = ['alpha','beta','gamma','delta','epsilon','theta','eta','ro','pi','sigma']
char = ['A','B','C','E','I','L','O','V']

with open('lab06/input.txt', 'r') as file1:
  file_in = file1.readlines()

extreme_weight = []
extreme_output = []

with open('lab06/output.txt', 'w') as file:
  NUM = int(file_in[0])

  for i in range(NUM):
    # Read mode in
    mode = int(file_in[1 + 2 * i + 0])

    # Read weights in
    in_weights = [int(val) for val in file_in[1 + 2 * i + 1 + 0].split()]

    code_book = {'A':'','B':'','C':'','E':'','I':'','L':'','O':'','V':''}

    #1. Do data structure augmentations
    queue = []
    for idx,w in enumerate(in_weights):
        queue.append([char[idx],-1,-1,w,''])

    tree = []
    tree_ptr = 0
    cnt = 0

    #2. Building huffman trees
    while queue != []:
        # Only root node left.
        if len(queue) == 1:
            node1 = queue.pop() # Right
            tree.append(node1)
            break

        # Sortings
        queue = bubble_sort(queue)

        # Extract the two queue with min weights and add those queue into the sub-tree list
        node1 = queue.pop() # Right
        node2 = queue.pop() # Left

        tree.append(node1)
        node1_idx = tree_ptr
        tree_ptr += 1

        tree.append(node2)
        node2_idx = tree_ptr
        tree_ptr += 1
        # Create dummy nodes
        sub_tree = [dummy_node_name[cnt],node2_idx,node1_idx,node1[3]+node2[3],'']

        if node1[3]+node2[3] == 28 and queue != []:
            # print(in_weights)
            extreme_weight.append([in_weights,node1[3]+node2[3]])

        cnt += 1
        # Push dummy nodes into queue list
        queue.append(sub_tree)

    #3. Tree postOrder traversal and produce the codebook
    # Traverse the tree using only idx
    stack = [len(tree)-1] #root

    while stack != []:
        # If left child, encode 0, right child encode 1
        cur_node_idx = stack.pop()

        # Extract current node from tree
        cur_node = tree[cur_node_idx]
        cur_char       = cur_node[0]
        cur_encode_bit = cur_node[4]

        if cur_char in code_book:
            code_book[cur_char] = cur_encode_bit

        left_child_idx = cur_node[1]
        right_child_idx = cur_node[2]

        # Visit left child, concatenate the encode bits, and put it into stack
        # Check if the left child is a leaf
        if left_child_idx != -1:
            tree[left_child_idx][4] = cur_encode_bit + '0'
            # Push its idx into stack
            stack.append(left_child_idx)

        # Visit right child, concatenate the encode bits, and put its children into stack
        # Check if the right child is a leaf
        if right_child_idx != -1:
            tree[right_child_idx][4] = cur_encode_bit + '1'
            # Push its idx into stack
            stack.append(right_child_idx)

    output = ''
    if mode == 0:
        for e in ['I','L','O','V','E']:
            output = output + code_book[e]
    else:
        for e in ['I','C','L','A','B']:
            output = output + code_book[e]

    # Write out the output and its length
    file.write(f"{len(output)}\n")
    for encoded_bits in output:
        file.write(f"{encoded_bits} ")

    file.write(f"\n")


# print(extreme_weight)
# print(extreme_output)