# Gives a list of boxes in the vagrant environment, and prompts user to choose one
def get_box
  count = 1
  boxes = `vagrant box list`.split(/\n/)
  boxes.each do |box|
    puts "#{count}) #{box}\n"
    count += 1
  end
  begin
    print "Choose a box from above: "
    inp = $stdin.readline.chomp
  end until (1 <= inp.to_i && inp.to_i <= (count - 1))
  box = boxes[inp.to_i - 1].split[0]
  return box
end

#Returns hash of indexed machine->box within vagrantfile directory
def get_indexed_vms(dir)
  machine_list = {}
  indexfile = "#{`echo $HOME`.chomp}/.vagrant.d/data/machine-index/index"
  File.foreach(indexfile) do |line|
    machineindex = JSON.parse(line)
    machineindex["machines"].each do |machine|
      if dir == machine[1]["vagrantfile_path"]
        machine_list[machine[1]["name"]] = machine[1]["extra_data"]["box"]["name"]
      end
    end
  end
  return machine_list
end

#Does what the name says
def split_command(args)
  main_args   = nil
  sub_command = nil
  sub_args    = []

  args.each_index do |i|
    if args[i].start_with?("-")
      args.delete(args[i])
    end
  end

  args.each_index do |i|
    if !args[i].start_with?("-")
      main_args   = args[0,i]
      sub_command = args[i]
      sub_args    = args[i+1, args.length - i + 1]
      break
    end
  end

  main_args = args.dup if main_args.nil?
  return [main_args, sub_command, sub_args]
end

#Returns the main argument and the last argument
def get_arguments(cmd)
  (main_args, sub_command, sub_args) = split_command(cmd)
  int_sub_command = '' #sub_command
  until sub_args.empty? do
    (int_main_args, int_sub_command, sub_args) = split_command(sub_args)
  end
  return [sub_command, int_sub_command]
end
