import pygame

def simulate(machinecode_filename, debug=True):
  opcode_labels = {
    0: 'nop',
    1: 'hlt',
    2: 'jmp',
    3: 'bif',
    4: 'cal',
    5: 'ret',
    6: 'pld',
    7: 'pst',
    8: 'mld',
    9: 'mst',
    10: 'adi',
    11: 'add',
    12: 'sub',
    13: 'bit',
    14: 'rsh',
    15: 'mul' }
  
  NUM_REGS = 8
  NUM_FLAGS = 4
  NUM_PORTS = 16
  DATA_SIZE = 2**8
  PROGRAM_SIZE = 2**10

  registers = [0] * NUM_REGS
  flags = [False] * NUM_FLAGS
  ports = [0] * NUM_PORTS
  data_memory = [0] * DATA_SIZE
  program_memory = [0] * PROGRAM_SIZE
  pc = 0

  lines = open(machinecode_filename).read().splitlines()
  
  for index, value in enumerate(lines):
    program_memory[index] = int(value, base=2)
  
  def print_state(registers, flags, ports, data_memory, program_memory, pc):
     print(f'PC = {pc}')
     print('Register Contents:')
     for i in range(len(registers)):
        print(f'R{i}: {registers[i]}')


  # pygame constants and functions
  
  FPS = 60
  CPS = 1000
  CPF = CPS // FPS

  grid_color = (76, 45, 28)
  off_color = (173, 101, 62)
  on_color = (242, 201, 159)
  screen_width = 32
  screen_height = 32
  lamp_size = 11

  grid_lines_size = lamp_size // 5
  width = (lamp_size + grid_lines_size) * screen_width + grid_lines_size
  height = (lamp_size + grid_lines_size) * screen_height + grid_lines_size

  def draw_pixel(x, y, on=True):
    fill_color = on_color if on else off_color
    x *= lamp_size + grid_lines_size
    y *= lamp_size + grid_lines_size

    x += grid_lines_size
    y += grid_lines_size

    y = height - y
    filled = 0

    pygame.draw.rect(window, fill_color, [x, y - lamp_size, lamp_size, lamp_size], filled)

  def draw_all_off():
    for x in range(screen_width):
        for y in range(screen_height):
            draw_pixel(x, y, on=False)

  # begin pygame loop

  pygame.init()
  window = pygame.display.set_mode((width, height))
  pygame.display.set_caption("new cpu")
  
  clock = pygame.time.Clock()
  running = True

  # Draw blank lamp screen
  window.fill(grid_color)
  draw_all_off()
  
  while running:
      clock.tick(FPS)
      for event in pygame.event.get():
          if event.type == pygame.QUIT:
              pygame.quit()
              running = False

      # Execute instruction
      registers[0] = 0 #r0 always reads 0

      instruction = program_memory[pc]
      
      opcode = opcode_labels[instruction >> 12]
      flag = (instruction >> 10) & 3
      instruction_memory_address = instruction & 1023    
      port = instruction & 255
      offset = instruction & 255
      immediate = instruction & 63
        if (immediate & 32): #negative
          immediate |= 

      
      pygame.display.update()

if __name__ == '__main__':
    simulate('output.mc')